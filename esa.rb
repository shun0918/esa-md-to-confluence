# frozen_string_literal: true

require 'faraday'
require 'json'
require 'redcarpet'

# Esa の Markdown ファイルから title, body, category を取得する
class Esa
  def initialize(path, token:, team:)
    File.open(path, 'r') do |file|
      @content = file.read
      metadata_raw, @body = @content.split("\n---\n")
      @metadata = metadata_raw.split("\n").reject { |x| x == '---' }.map do |x|
        key, *value = x.split(': ')
        if value.empty?
          [key, '']
        else
          [key, value.join(': ')] # value may contain `: `
        end
      end.to_h
    end

    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
    @client = Client.new(token:, team:)
  end

  def title
    @metadata['title'].strip.tr('"', '')
  end

  def body_html
    @markdown.render(@body)
  end

  def meta_html
    @markdown.render(@metadata.map { |key, value| "  - #{key}: #{value}" }.join("\n"))
  end

  def category
    @metadata['category'].split('/')[0]
  end

  def dir
    @metadata['category']
  end

  def created_at
    @metadata['created_at']
  end

  def updated_at
    @metadata['updated_at']
  end

  def id
    @metadata['number']
  end

  def comment_bodies_html
    @comment_bodies_html ||= client.fetch_comments(id).map { @markdown.render(_1['body_md']) }
  end

  private

  attr_reader :client

  class Client
    def initialize(team:, token:)
      @team = team
      @client = Faraday.new(url: 'https://api.esa.io') do |faraday|
        faraday.request :json
        faraday.request :url_encoded # encode post params
        faraday.adapter :net_http # Net::HTTP
        faraday.request :authorization, 'Bearer', token
      end
    end

    def fetch_comments(post_number)
      # https://docs.esa.io/posts/102#GET%20/v1/teams/:team_name/posts/:post_number/comments
      response = client.get("/v1/teams/#{team}/posts/#{post_number}/comments")
      json = JSON.parse(response.body)
      return json['comments'] if response.status == 200

      puts "[ERROR] Failed to fetch comments for post #{post_number}. #{json}"
      exit 1
    end

    private

    attr_reader :client, :team
  end
end
