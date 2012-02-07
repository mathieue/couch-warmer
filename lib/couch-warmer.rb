require 'couchrest'

class CouchWarmer
  # database =  'http://127.0.0.1:5984/dbname'
  def initialize(database)
    @db = CouchRest.database(database)
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
    tasks.map! { |t| t['task'] + ' ' + t['status'] }
    !tasks.empty?
  end

  def get_first_view(design_doc)
    design_info = CouchRest.get(@db.server.uri + '/' + @db.name + '/_design/' + design_doc)
    design_info["views"].keys.first
  end
end

