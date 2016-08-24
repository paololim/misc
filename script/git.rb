class Git

  def initialize(opts={})
    @root = opts.delete(:root) || '/web/gitcheckouts_for_upgrade'
  end

  # Checks out or updates the specified repo, yielding inside the local dir
  # @param full_repo e.g. flowcommerce/user
  def checkout(full_repo)
    owner, repo = full_repo.split("/", 2).map(&:to_s).map(&:strip)
    if owner == "" || repo == ""
      raise "Invalid repo[%s]" % full_repo
    end

    owner_dir = File.join(@root, owner)

    if !File.directory?(owner_dir)
      run("mkdir -p #{owner_dir}")
    end

    dir = File.join(owner_dir, repo)

    if File.exists?(dir)
      Dir.chdir(dir) do
        run("git reset --hard")
        run("git clean -fdx")
        run("git pull --quiet")
      end

    else
      Dir.chdir(owner_dir) do
        run("git clone git@github.com:%s/%s.git" % [owner, repo])
      end
    end

    Dir.chdir(dir) do
      yield dir
    end
  end

  def with_tmp_branch(name)
    current = current_branch
    current_date = Time.now.strftime("%Y%m%d_%H%M")
    tmp = "upgrade_#{name}_#{current_date}"
    begin
      run("git checkout master")
      run("git pull origin --rebase")
      run("git checkout -b #{tmp}")
      yield tmp
    ensure
      run("git checkout #{current}")
      run("git branch -D #{tmp}")
    end
  end

  def current_branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def run(command)
    puts " ==> " + command
    if !system(command)
      puts "FAILED"
      exit(1)
    end
  end
  
end
