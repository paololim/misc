#!/usr/bin/env ruby

# Runs docker image. Deletes all images except for the latest tag
#    (semver) for each image. Ignore any images that are not semver
#    tagged.
# Also removes any image whose repository is '<none>'

# Usage:
#    script/docker-rm-all-but-latest-tags.rb


headers = nil
all = {}
none = []

class Image

  attr_reader :repository, :tag, :sha

  def initialize(repository, tag, sha)
    @repository = repository
    @tag = tag
    @sha = sha
  end

end

class Tag

  attr_reader :major, :minor, :micro

  def initialize(major, minor, micro)
    @major = major
    @minor = minor
    @micro = micro
  end

  def label
    "%s.%s.%s" % [major, minor, micro]
  end
  
  def <=>(other)
    value = major <=> other.major
    if value == 0
      value = minor <=> other.minor
      if value == 0
        value = micro <=> other.micro
      end
    end
    value
  end
  
  def Tag.parse(value)
    if md = value.match(/^[vr]?(\d+)\.(\d+)\.(\d+)$/)
      Tag.new(md[1].to_i, md[2].to_i, md[3].to_i)
    else
      nil
    end
  end
  
end

`docker images`.strip.split("\n").each do |l|
  parts = l.strip.split(/\s+/).map(&:strip)
  if headers
    data = {}
    parts.each_with_index do |value, i|
      data[headers[i]] = parts[i]
    end
    repo = data[:repository]

    if repo == "<none>"
      none << data[:image]
    elsif tag = Tag.parse(data[:tag])
      all[repo] ||= []
      all[repo] << Image.new(repo, tag, data[:image])
    end
  else
    headers = parts.map(&:downcase).map(&:to_sym)
  end
end

none.each do |sha|
  cmd = "docker rmi -f #{sha} # <none>"
  puts cmd
  if system(cmd)
    puts "  - deleted"
  else
    puts " - error. could not delete"
  end
end

all.keys.sort.each do |repo|
  tags_to_drop = all[repo].map(&:tag).sort.reverse.drop(1)

  all[repo].each do |img|
    if tags_to_drop.include?(img.tag)
      cmd = "docker rmi -f #{img.sha} # #{repo}:#{img.tag.label}"
      puts cmd
      if system(cmd)
        puts "  - deleted"
      else
        puts " - error. could not delete"
      end
    end
  end
  #puts "#{repo}: #{tags.map(&:label).inspect}"
  #puts "#{repo}: #{tags.map(&:label).drop(1).inspect}"
end
                       
