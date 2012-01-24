require 'couchrest'

class CouchWarmer
  # database =  'http://127.0.0.1:5984/dbname'
  def initialize(database)
    @db = CouchRest.database!(database)
  end

  # name with suffix, suffix
  def warm(name, suffix)
    name = name[/(.*?)#{suffix}$/, 1]
    puts "warming.. #{name} from #{name}#{suffix}"
    begin
      src = @db.view('_design/' + name + suffix + '/_view/all')
    rescue RestClient::RequestTimeout => e
      puts "working hard...."
    end

    msg = "\rstill active.."
    while is_active?
      msg  << '.'
      print msg
      sleep 1
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
end

