# frozen_string_literal: true

require 'date'
require './confluence'
require './esa'

confluence = Confluence.new(
  host: ENV.fetch('CONFLUENCE_HOST'),
  user: ENV.fetch('CONFLUENCE_USER'),
  token: ENV.fetch('CONFLUENCE_API_TOKEN'),
  space_id: ENV.fetch('CONFLUENCE_SPACE_ID'),
  debug: true
)

target_dir = ARGV[0]
restart_at = ARGV[1]
raise 'Please specify a directory within the `esa` directory' if target_dir.nil?
raise "Directory `./esa/#{target_dir}` does not exist" unless Dir.exist?(target_dir)

confluence.create_root_page("#{DateTime.now.new_offset('+09:00').strftime('%Y-%m-%d %H:%M:%S')}")

skipping = !restart_at.nil?
Dir.glob('./esa/**/*').each do |path|
  next unless path.match?('md$')

  skipping = false if skipping && path.match?(restart_at)
  next if skipping

  p path
  esa = Esa.new(path)
  body = <<~BODY
    #{esa.meta_html}
    #{esa.body_html}
  BODY
  confluence.create_page(original_title: esa.title, body:, dir: esa.dir || '')
end
