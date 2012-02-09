require 'couchrest'

class CouchWarmer
  # database =  'http://127.0.0.1:5984/dbname'
  def initialize(database)
    @db = CouchRest.database(database)
  end

  def warm_all(suffix)
    puts "warming all with suffix #{suffix}"
    designs = get_all_design_docs suffix

    designs.each do |design|
      puts "warming #{design}"
      begin
        warm(design.gsub(suffix, ''), suffix)
      rescue RestClient::InternalServerError => e
        puts "error 500 on warming #{design} ..... -> next!"
      end
    end
  end

  # name with suffix, suffix
  def warm(name, suffix)
    puts "warming.. #{name} from #{name}#{suffix}"
    begin
      view_name = get_first_view(name + suffix)
      src = @db.view('_design/' + name + suffix + '/_view/' + view_name)
    rescue RestClient::RequestTimeout => e
      puts "working hard...."
    end

    msg = "still active.."
    counter = 1
    while is_active?
      print '.' if counter % 5 == 0
      sleep 1
      counter += 1
    end
    puts "copying.."
    after_warm(name + suffix, name)
    puts "warming #{name} from #{name}#{suffix} done!!!"
  end

  private
  def after_warm(src, dest)
    begin
      dest = @db.view('_design/%s' % dest)
    rescue RestClient::ResourceNotFound => e
      puts "%s does not exists.." % dest
      dest = '_design/%s' % dest
    end
    src = @db.view('_design/%s' % src)
    @db.copy_doc(src, dest)
  end

  def is_active?
    tasks = CouchRest.get(@db.server.uri + '/_active_tasks')
    tasks.reject! { |t| t['type'] != 'View Group Indexer' }
    tasks.map! { |t| t['task'] + ' ' + t['status'] }
    !tasks.empty?
  end

  def get_first_view(design_doc)
    design_info = CouchRest.get(@db.server.uri + '/' + @db.name + '/_design/' + design_doc)
    design_info["views"].keys.first
  end

  def get_all_design_docs(suffix)
    designs = CouchRest.get(@db.server.uri + '/' + @db.name + '/_all_docs?startkey=%22_design/%22&endkey=%22_design0%22&include_docs=true')
    designs["rows"].map {|d| d["id"].gsub '_design/', '' }.grep /#{suffix}$/
  end
  
end

