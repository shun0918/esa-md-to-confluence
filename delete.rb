# frozen_string_literal: true

require 'date'
require './confluence'

confluence = Confluence.new(
  host: ENV.fetch('CONFLUENCE_HOST'),
  user: ENV.fetch('CONFLUENCE_USER'),
  token: ENV.fetch('CONFLUENCE_API_TOKEN'),
  space_id: ENV.fetch('CONFLUENCE_SPACE_ID'),
  debug: true
)

confluence.delete_all_pages
