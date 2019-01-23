# This is derived version of https://github.com/mojombo/jekyll/blob/master/lib/jekyll/migrators/wordpress.rb

$KCODE='UTF8'
require 'rubygems'
require 'sequel'
require 'fileutils'
require 'yaml'
require 'ya2yaml'

module Jekyll
  module WordPress

    QUERY = "select post_title, post_name, post_date, post_content, post_excerpt, ID, guid from wp_posts where post_status = 'publish' and post_type = 'post'"

    def self.process(dbname, user, pass, host = 'localhost')
      db = Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :encoding => 'utf8')

      FileUtils.mkdir_p "_posts"

      db[QUERY].each do |post|
        # Get required fields and construct Jekyll compatible name
        title = post[:post_title]
        slug = post[:post_name]
        date = post[:post_date]
        content = post[:post_content]
        name = "%02d-%02d-%02d-%s.md" % [date.year, date.month, date.day, slug]

        tag_query = "SELECT * FROM wp_term_relationships r, wp_term_taxonomy ta, wp_terms t where r.object_id=#{post[:ID]} and r.term_taxonomy_id=ta.term_taxonomy_id and ta.taxonomy='post_tag' and ta.term_id=t.term_id"

        tags = db[tag_query].map { |tag| tag[:slug] }

        data = {
           'layout' => 'post',
           'title' => title.to_s,
           'date' => date,
           'tags' => tags,
         }.delete_if { |k,v| v.nil? || v == ''}.ya2yaml(:syck_compatible => true)

        # Write out the data and content to file
        File.open("_posts/#{name}", "w") do |f|
          f.puts data
          f.puts "---"
          f.puts content
        end
      end

    end
  end
end
