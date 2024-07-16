# frozen_string_literal: true

require 'faraday'
require 'json'
require 'redcarpet'

# Confluence 用のクライアント
class Confluence
  def initialize(host:, user:, token:, space_id:)
    @client = Client.new(host:, user:, token:, space_id:)
    @page_id_by_path = {}
  end

  def create_page(title:, body:, dir:)
    create_dir(dir) if !dir.empty? && dir_id(dir).nil?

    response = client.create_page(title, body, dir_id(dir))
    path = dir.empty? ? title : "#{dir}/#{title}"
    @page_id_by_path[path] = response['id']
    response
  end

  def delete_all_pages
    client.delete_all_pages
  end

  def create_comment(page_id, body)
    client.create_comment(page_id, body)
  end

  private

  attr_reader :client

  def dir_id(dir)
    @page_id_by_path[dir]
  end

  def create_dir(dir)
    return if dir == ''

    dir_list = dir.split('/')
    title = dir_list.pop
    parent_dir = dir_list.any? ? dir_list.join('/') : ''

    create_page(title:, body: '', dir: parent_dir)
  end

  # Confluence API のクライアント
  class Client
    def initialize(host:, user:, token:, space_id:)
      @client = Faraday.new(url: host) do |faraday|
        faraday.request :url_encoded # encode post params
        faraday.adapter :net_http # Net::HTTP
        faraday.request :authorization, :basic, user, token
      end
      @space_id = space_id
    end

    def create_page(title, body, parent_id = nil)
      print "[LOG] Create page: #{title}\n"

      response = client.post('/wiki/api/v2/pages') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          "type": 'page',
          "title": title,
          "spaceId": @space_id,
          "status": 'current',
          "root-level": parent_id.nil?,
          "parentId": parent_id,
          "body": {
            "representation": 'storage',
            "value": body,
          },
        }.compact.to_json
      end
      json = JSON.parse(response.body)

      if response.status == 400 &&
         json['errors'][0]['title']&.match(/^A page with this title already exists/) &&
         confirmed?("The page '#{title}' already exists. Do you want to overwrite it?")
        page = fetch_page_by_title(title)
        delete_page(page)
        return create_page(title, body, parent_id)
      end

      if response.status != 200
        puts "[ERROR] #{json}"
        exit 1
      end

      puts "[SUCCESS] #{json}"
      json
    end

    def create_comment(page_id, body)
      puts "[LOG] Create comment: to page #{page_id}"
      response = client.post("/wiki/api/v2/footer-comments") do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          "type": 'comment',
          "pageId": page_id,
          "body": { "representation": 'storage', "value": body }
        }.to_json
      end
      json = JSON.parse(response.body)

      if response.status != 201
        puts "[ERROR] #{json}"
        exit 1
      end

      puts "[SUCCESS] #{json}"
      json
    end

    def delete_all_pages
      loop do
        pages = fetch_pages
        break if pages.empty?

        delete_pages(pages)
      end
    end

    def fetch_pages
      response = client.get('/wiki/api/v2/pages') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['limit'] = 100
        req.params['space-id'] = @space_id
      end
      json = JSON.parse(response.body)
      return json['results'] if response.status == 200

      puts "[ERROR] #{json}"
      exit 1
    end

    def delete_pages(pages)
      pages.each { |page| puts "(#{page['spaceId']}) #{page['title']}" }
      exit 1 unless confirmed?('Delete these pages?')

      pages.each { delete_page(_1) }
    end

    def delete_page(page)
      raise '[ERROR] The space ID of the page is different.' unless page['spaceId'] == @space_id

      response = client.delete("/wiki/api/v2/pages/#{page['id']}")

      if response.status != 204
        json = JSON.parse(response.body)
        puts "[ERROR] #{json}"
        exit 1
      end

      puts "[SUCCESS] Delete: #{page['title']}"
    end

    def confirmed?(text)
      puts "#{text} [y/N]: "
      $stdin.gets.chomp == 'y'
    end

    private

    def fetch_page_by_title(title)
      puts "[LOG] Fetch page: #{title}"
      response = client.get('/wiki/api/v2/pages') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['title'] = title
        req.params['space-id'] = @space_id
        req.params['sort'] = 'title'
      end
      json = JSON.parse(response.body)
      return json['results'].find { _1['title'] == title } if response.status == 200 && json['results'].any?

      puts "[ERROR] #{json}"
      exit 1
    end

    attr_reader :client
  end
end