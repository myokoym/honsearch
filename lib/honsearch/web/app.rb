# class Honsearch::Web::App
#
# Copyright (C) 2016  Masafumi Yokoyama <myokoym@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "honsearch"
require "active_support/core_ext/hash"
require "sinatra/base"
require "sinatra/json"
require "sinatra/cross_origin"
require "sinatra/reloader"
require "haml"
require "padrino-helpers"
require "kaminari/sinatra"

require_relative "honsearch-kaminari"

module Honsearch
  module Web
    module PaginationProxy
      def limit_value
        page_size
      end

      def total_pages
        n_pages
      end
    end

    class App < Sinatra::Base
      I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
      I18n.available_locales = [:ja, :en, :"ja-JP"]
      I18n.default_locale = :ja
      helpers Kaminari::Helpers::SinatraHelpers
      register Sinatra::CrossOrigin

      configure :development do
        register Sinatra::Reloader
      end

      before do
        @sub_url = ENV["HONSEARCH_SUB_URL"]
      end

      get "/" do
        haml :index
      end

      get "/search" do
        if params[:reset_params]
          params.reject! do |key, _value|
            key != "word"
          end
          redirect to('/search?' + params.to_param)
        end
        search_and_paginate
        haml :index
      end

      get "/search.json" do
        cross_origin
        search_and_paginate
        books = @paginated_books || @books
        json books.collect {|book| book.attributes }
      end

      get "/similar" do
        haml :similar
      end

      post "/similar" do
        database = GroongaDatabase.new
        database.open(Command.new.database_dir)
        searcher = GroongaSearcher.new
        text = params[:text] || ""
        @books = searcher.similar_search_by_text(database, text).take(50)
        haml :similar
      end

      helpers do
        def search_and_paginate
          if params[:word]
            words = params[:word].split(/[[:space:]]+/)
          else
            words = []
          end
          options ||= {}
          options[:author_id] = params[:author_id] if params[:author_id]
          options[:publisher] = params[:publisher] if params[:publisher]
          options[:pubyear] = params[:pubyear] if params[:pubyear]
          options[:pubage] = params[:pubage] if params[:pubage]
          options[:ccode1] = params[:ccode1] if params[:ccode1]
          options[:ccode2] = params[:ccode2] if params[:ccode2]
          options[:ccode3] = params[:ccode3] if params[:ccode3]
          options[:ccode4] = params[:ccode4] if params[:ccode4]

          database = GroongaDatabase.new
          database.open(Command.new.database_dir)
          searcher = GroongaSearcher.new
          @books = searcher.search(database, words, options)
          @snippet = searcher.snippet
          page = (params[:page] || 1).to_i
          size = (params[:n_per_page] || 20).to_i
          begin
            @paginated_books = @books.paginate([["_score", :desc], ["_id", :desc]],
                                               page: page,
                                               size: size)
          rescue Groonga::TooLargePage
            params.delete(:page)
            @paginated_books = @books.paginate([["_score", :desc], ["_id", :desc]],
                                               page: 1,
                                               size: size)
          end
          @paginated_books.extend(PaginationProxy)
          @paginated_books
        end

        def params_to_description
          words = []
          if params[:author_id]
            words << "著者:#{params[:author_id]}"
          end
          if params[:publisher]
            words << "出版社:#{params[:publisher]}"
          end
          if params[:pubyear]
            words << "発行年:#{params[:pubyear]}"
          end
          if params[:pubage]
            words << "発行年代:#{params[:pubage]}"
          end
          if params[:ccode1]
            words << "販売対象: #{params[:ccode1]}"
          end
          if params[:ccode2]
            words << "形態:#{params[:ccode2]}"
          end
          if params[:ccode4] || params[:ccode3]
            words << "内容:#{params[:ccode4] || params[:ccode3]}"
          end
          if words.empty?
            ""
          else
            words.collect! do |word|
              "「#{word}」"
            end
            "（#{words.join}で絞り込み中）"
          end
        end

        def grouping_by_authors(table)
          key = "authors"
          table.group(key).sort_by {|item| item.n_sub_records }.last(100).reverse
        end

        def grouping_by_publisher(table)
          key = "publisher"
          table.group(key).sort_by {|item| item.n_sub_records }.last(100).reverse
        end

        def grouping_by_pubyear(table)
          key = "pubyear"
          table.group(key).sort_by {|item| item._key }.reverse
        end

        def grouping_by_pubage(table)
          key = "pubage"
          table.group(key).sort_by {|item| item._key }.reverse
        end

        def drilled_url(author)
          url(["/search", drilled_params(author_id: author._key)].join("?"))
        end

        def drilled_label(author)
          "#{author.name} (#{author.n_sub_records})"
        end

        def drilled_params(additional_params)
          additional_params = Hash[
            additional_params.map do |key, value|
              [key.to_s, value]
            end
          ]
          tmp_params = params.dup
          tmp_params.merge!(additional_params)
          tmp_params.delete("page")
          tmp_params.to_param
        end

        def groonga_version
          Groonga::VERSION[0..2].join(".")
        end

        def rroonga_version
          Groonga::BINDINGS_VERSION.join(".")
        end

        def snippets
          snippet = Groonga::Snippet.new(width: 100,
                                         default_open_tag: "<span class=\"keyword\">",
                                         default_close_tag: "</span>",
                                         html_escape: true,
                                         normalize: true)
          words.each do |word|
            snippet.add_keyword(word)
          end

          snippet.execute(selected_books.first.content)
        end

        def last_update_time
          path = File.join(settings.root, "..", "..", "..", "aozorabunko")
          if File.exist?(path)
            File.mtime(path)
          else
            nil
          end
        end

        def last_update_date
          return unless last_update_time
          last_update_time.strftime("%Y-%m-%d")
        end

        def page_title
          title = "Honsearch 書誌情報検索"
          if params[:word]
            title = "#{params[:word]}#{params_to_description} - #{title}"
          end
          title
        end
      end
    end
  end
end
