require 'yaml'

class DeployTower < Sinatra::Base

  REPOS = YAML.load(File.read(File.join(settings.root, 'config.yml')))

  set :root, File.dirname(__FILE__)

  helpers do
    def protected!(repo_name)
      unless authorized?(repo_name)
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?(repo_name)
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && REPOS.has_key?(repo_name) && @auth.credentials == [repo_name, REPOS[repo_name.downcase]["api_key"]]
    end
  end

  get '/' do
    "Good news everyone! DeployTower is here"
  end

  # GET /deploy/:repo_name
  # Optional parameters:
  #  - branch - branch to deploy
  get '/deploy/:repo_name' do
    protected!(params[:repo_name].downcase)

    repo_name = params[:repo_name].downcase
    repo = REPOS[repo_name]
    root = settings.root
    branch = params[:branch] || repo["local_branch"] || 'master'

    puts ">> Deploying #{branch} branch"

    %x(mkdir -p #{root}/repos)

    cmds = []

    # Try to load repo, check out if necessary
    cmds << "cd #{root}/repos"
    cmds << "if [ -d #{repo_name} ] ; then rm -rf #{repo_name} ; fi"
    cmds << "git clone #{repo["git"]} #{repo_name}"
    cmds << "cd #{root}/repos/#{repo_name}"

    # Update the codez
    cmds << "git checkout #{branch}"

    # Add heroku remote
    cmds << "git remote add heroku #{repo["heroku"]}"

    # Deploy that puppy
    cmds << "git push -f heroku #{branch}:master"
    
    # Migrate the hell out of that mofo
    cmds << "heroku run rake db:migrate"
    cmds << "heroku restart"

    # Cleanup
    cmds << "cd #{root}"
    cmds << "rm -rf #{root}/repos/#{repo_name}"

    # EXECUTE! EXECUTE! EXECUTE!
    bb = IO.popen(cmds.join(" && "))
    b = bb.readlines
    puts b.join("\n")
  end
end
