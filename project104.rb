#!/usr/bin/env ruby

# Project104
# Downloads photos from a Tumblr blog
# Uses the tumblr_client gem https://github.com/tumblr/tumblr_client
# Pass the name of the blog as an argument. Ex: project104.rb "myblog.tumblr.com"

require 'json'
require 'tumblr_client'
require "net/http"

# Register your app and get your keys, tokens, and secrets.
# Details at https://www.tumblr.com/docs/en/api/v2
CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OAUTH_TOKEN = ""
OAUTH_TOKEN_SECRET = ""

def getFile(blogname, file_uri)
  uri = URI(file_uri)
  destination = blogname + "/" + uri.path.split('/').last
  Net::HTTP.start(uri.host) do |http|
    resp = http.get(uri.path)
    if !File.exists?(destination)
      open(destination, "wb") do |file|
          file.write(resp.body)
      end
    end
  end
end

Tumblr.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
end

client = Tumblr::Client.new

blog_host = ARGV[0]

info = client.blog_info(blog_host)
blog_name = info["blog"]["name"]
total_posts = info["blog"]["posts"]

# Uses the first part of your blog name as the folder name
Dir.mkdir(blog_name) unless File.exists?(blog_name)

puts "Processing " + total_posts.to_s + " total posts on " + blog_name

# Tumblr API limits responses to 20 posts.
# Specifies 0-based offset of next group of posts to grab.
offset = 0

while offset < total_posts do
  # You can grab posts of only a given type, specified here by :type
  # For details on available types see https://www.tumblr.com/docs/en/api/v2#posts
  posts = client.posts(blog_host, :type => "photo", :offset => offset)

  posts["posts"].each do |post|
    post["photos"].each do |photo|
      puts "getting " + photo["original_size"]["url"]
      getFile(blog_name, photo["original_size"]["url"])
      sleep(2)
    end
  end
  offset += 20
end
