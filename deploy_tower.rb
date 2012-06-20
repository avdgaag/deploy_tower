require 'yaml'

class DeployTower < Sinatra::Base

  REPOS = YAML.load(File.read(File.join(settings.root, 'config.yml')))

  set :root, File.dirname(__FILE__)

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if @auth.provided? && @auth.basic? && @auth.credentials
        repo_name, api_key = @auth.credentials
        REPOS.has_key?(repo_name.downcase) && REPOS[repo_name.downcase]["api_key"] == api_key
      end
    end
  end

  get '/' do
    "Good news everyone! DeployTower is here"
  end

  # GET /deploy/:repo_name
  # Optional parameters:
  #  - branch - branch to deploy
  get '/deploy/:repo_name' do
    protected!

    repo_name = params[:repo_name].downcase
    repo = REPOS[repo_name]
    root = settings.root
    branch = params[:branch] || REPOS["local_branch"] || 'master'

    %x(mkdir -p #{root}/repos)

    cmds = []

    # Try to load repo, check out if necessary
    cmds << "cd #{root}/repos"
    cmds << "git clone #{repo["git"]} #{repo_name}"
    cmds << "cd #{root}/repos/#{repo_name}"

    # Update the codez
    cmds << "git checkout #{branch}"

    # Add heroku remote
    cmds << "git remote add heroku #{repo["heroku"]}"

    # Deploy that puppy
    cmds << "git push heroku #{branch}:master"

    # Cleanup
    cmds << "cd #{root}"
    cmds << "rm -rf #{root}/repos/#{repo_name}"

    # EXECUTE! EXECUTE! EXECUTE!
    bb = IO.popen(cmds.join(" && "))
    b = bb.readlines
    puts b.join("\n")
  end
end
