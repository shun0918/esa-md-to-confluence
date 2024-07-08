# frozen_string_literal: true

# Esa の Markdown ファイルから title, body, category を取得する
class Esa
  def initialize(path)
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
end
