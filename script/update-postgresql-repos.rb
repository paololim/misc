#!/usr/bin/env ruby

dir = File.dirname(__FILE__)
load File.join(dir, 'git.rb')

repos = %w(flowvault/payment-postgresql flowcommerce/token-postgresql flowcommerce/message-postgresql flowcommerce/message-postgresql flowcommerce/tracking-postgresql flowcommerce/label-postgresql flowcommerce/inventory-postgresql flowcommerce/fulfillment-postgresql flowcommerce/ratecard-postgresql flowcommerce/catalog-postgresql flowcommerce/experience-postgresql flowcommerce/metric-postgresql flowcommerce/lib-postgresql flowcommerce/organization-postgresql flowcommerce/harmonization-postgresql flowcommerce/webhook-postgresql flowcommerce/currency-postgresql flowcommerce/delta-postgresql flowcommerce/book-postgresql flowcommerce/registry-postgresql flowcommerce/search-postgresql flowcommerce/splashpage-postgresql flowcommerce/research-postgresql flowcommerce/email-postgresql flowcommerce/email-postgresql flowcommerce/classification-postgresql flowcommerce/user-postgresql flowcommerce/dependency-postgresql flowcommerce/demo-postgresql)

git = Git.new

git.checkout("flowcommerce/docker") do |docker|
  dockerfiles = [
    File.join(docker, "templates/postgresql/Dockerfile"),
    File.join(docker, "templates/postgresql/.dockerignore")
  ]

  dockerfiles.each do |path|
    if !File.exists?(path)
      raise "Missing #{path}"
    end
  end
  
  git.checkout("flowcommerce/lib-postgresql") do |dir|
    upgrades = Dir.glob(File.join(dir, "upgrades/*.sql"))
    
    repos.each do |r|
      puts r
      git.checkout(r) do
        added = []
        deleted = []

        upgrades.each do |source|    
          target = File.join("scripts", File.basename(source))
          if File.exists?(target)
            if IO.read(target).strip != IO.read(source).strip
              puts "ERROR: %s/%s exists already - expected a unique filename for the upgrade script %s" % [r, target, source]
            end
          else
            git.run("cp %s %s" % [source, target])
            git.run("git add %s" % target)
            added << target
          end
        end

        dockerfiles.each do |source|
          target = File.basename(source)
          if File.exists?(target) && IO.read(target).strip == IO.read(source).strip
          ## No-op
          else
            git.run("cp %s %s" % [source, target])
            git.run("git add %s" % target)
            added << target
          end
        end

        ['scripts/Dockerfile', 'scripts/.dockerignore'].each do |target|
          if File.exists?(target)
            git.run("git rm -f %s" % target)
            deleted << target
          end
        end

        if !added.empty? || !deleted.empty?
          git.run("git commit -m 'Upgrade lib-postgresql' %s" % added.join(" "))
          git.run("git push origin master")
          git.run("dev tag")
          git.run("dev build_docker_image")
        end
      end
    end
  end
end
