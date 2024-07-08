# frozen_string_literal: true

require 'faraday'
require 'json'
require 'redcarpet'

# Confluence 用のクライアント
class Confluence
  def initialize(host:, user:, token:, space_id:, debug: false)
    @client = Client.new(host:, user:, token:, space_id:)
    @page_id_by_path = {}
    @debug = debug
  end

  def create_page(original_title:, body:, dir:)
    create_dir(dir) if dir_id(dir).nil?

    response = client.create_page("#{original_title}_#{unique_suffix}", body, dir_id(dir))
    path = dir.empty? ? original_title : "#{dir}/#{original_title}"
    @page_id_by_path[path] = response['id']
    response
  end

  def create_root_page(title)
    root_page = client.create_page(title, '', nil)
    @page_id_by_path[''] = root_page['id']
    root_page
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

    create_page(original_title: title, body: '', dir: parent_dir)
  end

  def unique_suffix
    Time.now.to_i
  end

  def debug?
    @debug
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

      if response.status != 200
        puts "[ERROR] #{json}"
        exit 1
      end

      puts "[SUCCESS] #{json}"
      json
    end

    private

    attr_reader :client
  end
end