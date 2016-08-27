#!/usr/bin/env ruby

dir = File.dirname(__FILE__)
load File.join(dir, 'git.rb')

group_id = ARGV.shift.to_s.strip
artifact_id = ARGV.shift.to_s.strip
version = ARGV.shift.to_s.strip

if group_id.empty? || artifact_id.empty? || version.empty?
  puts "Pls specify group_id, artifact_id, and version"
  exit(1)
end

class Upgrader

  def initialize(group_id, artifact_id, version)
    @git = Git.new
    @group_id = group_id
    @artifact_id = artifact_id
    @version = version
  end

  def upgrade(owner, repo)
    num = 60
    label = "--- %s/%s" % [owner, repo]
    puts "-" * num
    puts label + (" " * (num - label.size - 3)) + "---"
    puts "-" * num

    @git.checkout("%s/%s" % [owner, repo]) do
      build = "build.sbt"
      if File.exists?(build)
        upgrade_file(build)
        puts ""
      else
        puts "WARNING: No build.sbt file found in root - skipping"
      end
    end
  end

  def clean(value)
    value.strip.sub(/,$/, '').sub(/^\"+/, '').sub(/\"+$/, '').sub(/^\'+/, '').sub(/\'+$/, '')
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

        @git.with_tmp_branch("%s.%s" % [@group_id, @artifact_id]) do |name|
          commands.each do |cmd|
            @git.run(cmd.sub(/{branch_name}/, name))
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
  "io.flow.lib-play" => [
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
  
  "io.flow.lib-event" => [
    'flowcommerce/lib-message-event',
    'flowcommerce/lib-catalog-event',
    'flowcommerce/lib-harmonization-event',
    'flowcommerce/lib-currency-event',
    'flowcommerce/lib-email',
    'flowcommerce/lib-experience-event',
    'flowcommerce/lib-organization-event',
  ],
  
  "io.flow.lib-price" => [
    'flowcommerce/experience',
    'flowcommerce/fulfillment',
    'flowcommerce/catalog',
    'flowcommerce/harmonization',
    'flowcommerce/metric'
  ],

  "io.flow.lib-catalog-event" => [
    'flowcommerce/harmonization',
    'flowcommerce/fulfillment',
    'flowcommerce/metric',
    'flowcommerce/webhook',
    'flowcommerce/catalog'
  ],

  "io.flow.lib-currency-event" => [
    'flowcommerce/currency',
    'flowcommerce/metric'
  ],

  "io.flow.lib-harmonization-event" => [
    'flowcommerce/harmonization',
    'flowcommerce/metric',
    'flowcommerce/webhook'
  ],
  
  "io.flow.lib-experience-event" => [
    'flowcommerce/experience',
    'flowcommerce/metric',
    'flowcommerce/webhook'
  ],
  
  "io.flow.lib-organization-event" => [
    'flowcommerce/experience',
    'flowcommerce/metric',
    'flowcommerce/organization'
  ],
  
  "io.flow.lib-logistics" => [
    'flowcommerce/tracking'
  ],

  "io.flow.lib-message-event" => [
    'flowcommerce/fulfillment',
    'flowcommerce/message'
  ],

  "io.flow.lib-email" => [
    'flowcommerce/catalog',
    'flowcommerce/email',
    'flowcommerce/organization',
    'flowcommerce/user',
  ],

  "io.flow.lib-reference" => [
    'flowcommerce/lib-price',
    'flowcommerce/lib-message-event',
    'flowcommerce/tracking',
    'flowcommerce/classification',
    'flowvault/payment',
    'flowcommerce/search',
    'flowcommerce/splashpage',
    'flowcommerce/ratecard',
    'flowcommerce/organization',
    'flowcommerce/currency',
    'flowcommerce/location',
    'flowcommerce/ratecard',
    'flowcommerce/research',
  ],

  'com.sendgrid.sendgrid-java' => [
    'flowcommerce/delta',
    'flowcommerce/dependency',
    'flowcommerce/apidoc',
    'flowcommerce/email'
  ]
}

key = "#{group_id}.#{artifact_id}"
all = repos[key]
if all.nil?
  puts "No repos configured for %s" % key
else
  all.each do |repo|
    owner, name = repo.split("/", 2)
    upgrader.upgrade(owner, name)
  end
end
