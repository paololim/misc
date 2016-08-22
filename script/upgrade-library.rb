#!/usr/bin/env ruby

group_id = ARGV.shift.to_s.strip
artifact_id = ARGV.shift.to_s.strip
version = ARGV.shift.to_s.strip

if group_id.empty? || artifact_id.empty? || version.empty?
  puts "Pls specify group_id, artifact_id, and version"
  exit(1)
end

class Upgrader

  def initialize(group_id, artifact_id, version)
    @group_id = group_id
    @artifact_id = artifact_id
    @version = version
  end

  def upgrade(owner, repo)
    puts "%s/%s" % [owner, repo]

    local_checkout_root = "/web/gitcheckouts_for_upgrade"
    owner_dir = File.join(local_checkout_root, owner)

    if !File.directory?(owner_dir)
      run("mkdir -p #{owner_dir}")
    end

    dir = File.join(owner_dir, repo)

    if File.exists?(dir)
      Dir.chdir(dir) do
        run("git pull --quiet")
      end

    else
      Dir.chdir(owner_dir) do
        run("git clone git@github.com:%s/%s.git" % [owner, repo])
      end
    end
  
    Dir.chdir(dir) do
      build = File.join(dir, "build.sbt")
      if File.exists?(build)
        upgrade_file(build)
        puts ""
      else
        puts "WARNING: No build.sbt file found in root - skipping"
      end
    end
  end

  def run(command)
    puts " ==> " + command
    if !system(command)
      puts "FAILED"
      exit(1)
    end
  end

  def clean(value)
    value.strip.sub(/,$/, '').sub(/^\"+/, '').sub(/\"+$/, '').sub(/^\'+/, '').sub(/\'+$/, '')
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

  def upgrade_file(path)
    old_version = nil
    tmp = "/tmp/upgrade-lib.#{Process.pid}.tmp"
    begin
      File.open(tmp, "w") do |out|
        IO.readlines(path).each do |l|
          parts = l.split(/%+/).map { |part| clean(part) }.select { |p| !p.empty? }
          if parts.size > 2 && parts[0] == @group_id && parts[1] == @artifact_id
            old_version = parts[2]
            if old_version != @version
              out << l.sub(old_version, @version)
            else
              out << l
            end
          else
            out << l
          end
        end
      end

      if old_version.nil?
        puts " does not have %s.%s" % [@group_id, @artifact_id]
        false

      elsif old_version == @version
        puts " %s.%s already is on version %s" % [@group_id, @artifact_id, @version]

      else
        puts " %s.%s upgrading from %s to %s" % [@group_id, @artifact_id, old_version, @version]
        msg = "Upgrade %s.%s from %s => %s" % [@group_id, @artifact_id, old_version, @version]

        dir = File.dirname(path)
        commands = []
        if File.exists?(File.join(dir, ".apidoc"))
          commands << "apidoc update"
        end

        commands << "mv %s %s" % [tmp, path]
        commands << "git add %s" % path
        commands << "git commit --allow-empty -a -m '%s'" % msg
        commands << "git push origin {branch_name}"
        commands << "hub pull-request -m '%s'" % msg

        with_tmp_branch("%s.%s" % [@group_id, @artifact_id]) do |name|
          commands.each do |cmd|
            run(cmd.sub(/{branch_name}/, name))
          end
        end
      end

    ensure
      if File.exists?(tmp)
        File.delete(tmp)
      end
    end
  end

end

upgrader = Upgrader.new(group_id, artifact_id, version)

## TODO: Fetch this from dependency
repos = {
  "lib-play" => [
    'flowcommerce/lib-algolia',
    'flowcommerce/lib-event',
    'flowcommerce/lib-logistics',
    'flowcommerce/classification',
    'flowcommerce/research',
    'flowcommerce/registry',
    'flowcommerce/location',
    'flowcommerce/inventory',
    'flowcommerce/token',
    'flowcommerce/search',
    'flowcommerce/splashpage',
    'flowcommerce/ratecard',
    'flowvault/payment'
  ],
  
  "lib-event" => [
    'flowcommerce/lib-message-event',
    'flowcommerce/lib-catalog-event',
    'flowcommerce/lib-harmonization-event',
    'flowcommerce/lib-currency-event',
    'flowcommerce/lib-email',
    'flowcommerce/lib-experience-event',
    'flowcommerce/lib-organization-event',
  ],
  
  "lib-price" => [
    'flowcommerce/experience',
    'flowcommerce/fulfillment',
    'flowcommerce/catalog',
    'flowcommerce/harmonization',
    'flowcommerce/metric'
  ],

  "lib-catalog-event" => [
    'flowcommerce/harmonization',
    'flowcommerce/fulfillment',
    'flowcommerce/metric',
    'flowcommerce/webhook',
    'flowcommerce/catalog'
  ],

  "lib-currency-event" => [
    'flowcommerce/currency'
  ],

  "lib-logistics" => [
    'flowcommerce/tracking'
  ],

  "lib-message-event" => [
    'flowcommerce/message'
  ],

  "lib-email" => [
    'flowcommerce/email',
    'flowcommerce/user'
  ]
}

all = repos[artifact_id]
if all.nil?
  puts "No repos configured for %s" % artifact_id
else
  all.each do |repo|
    owner, name = repo.split("/", 2)
    upgrader.upgrade(owner, name)
  end
end
