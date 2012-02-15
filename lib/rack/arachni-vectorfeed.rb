=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'rack/utils'
require 'yaml'
require 'digest/md5'
# require 'ap'

module Rack
    class ArachniVectorFeed
        include Rack::Utils

        def initialize( app, opts )
            @app  = app
            @opts = opts

            raise "Option 'outfile' is mandatory." if !opts[:outfile]

            @vectors = Set.new
        end

        def call( env )
            extract_vectors( env ).each { |vector| append_to_outfile( vector ) }

            # forward the request up to the app
            code, headers, body = @app.call( env )

            append_to_outfile( extract_page( env, code, headers, body ) )

            [ code, headers, body ]
        end

        private

        def append_to_outfile( vector )
            digest = Digest::MD5.hexdigest( vector.to_s )
            return if @vectors.include? digest

            ::File.open( @opts[:outfile], 'a' ) do |out|
                YAML.dump( [vector], out )
            end

            @vectors << digest
        end

        def extract_vectors( env )
            [extract_cookies( env ), extract_headers( env ),
            extract_forms( env ), extract_links( env ) ].flatten.compact
        end

        def extract_page( env, code, headers, body )
            {
                'type'    => 'page',
                'url'     => vector_tpl( env )['action'],
                'code'    => code,
                'headers' => headers.to_hash,
                'body'    => body.join( "\n" )
            }
        end

        def extract_links( env )
            return if !env['QUERY_STRING']

            input_arr = env['QUERY_STRING'].split( '&' ).map {
                |pair|
                k, v = pair.split( '=', 2 )
                { k => v }
            }

            inputs = {}
            input_arr.each {
                |input|
                inputs.merge!( input )
            }

            if !inputs.empty?
                vector_tpl( env ).merge(
                    'type' => 'link',
                    'method' => 'get',
                    'inputs' => inputs
                )
            end
        end

        def extract_forms( env )
            return if !env['rack.request.form_hash']

            vector_tpl( env ).merge(
                'type' => 'form',
                'inputs' => env['rack.request.form_hash']
            )
        end

        def extract_cookies( env )
            return if !env['HTTP_COOKIE'] || env['HTTP_COOKIE'].empty?

            env['HTTP_COOKIE'].split( '; ' ).map {
                |pair|
                k, v = pair.split( '=', 2 )
                { k => v }
            }.map {
                |cookie|
                vector_tpl( env ).merge(
                    'method' => 'get',
                    'type'   => 'cookie',
                    'inputs' => cookie
                )
            }
        end

        def extract_headers( env )
            # this handles request headers
            headers = {}
            env.select { |k,v| k.start_with? 'HTTP_' }
                .collect { |pair| [pair[0].sub( /^HTTP_/, ''), pair[1] ] }
                .sort.map {
                    |k, v|
                    canon = k.gsub( '_', '-' ).capitalize
                    vector_tpl( env ).merge(
                        'method' => 'get',
                        'type'   => 'header',
                        'inputs' => { canon => v }
                    )
                }
        end

        def vector_tpl( env )
            vector = {
                'method' => env['REQUEST_METHOD'].downcase,
                'action' => env['rack.url_scheme'] + '://' + env['HTTP_HOST'] +
                    env['REQUEST_URI']
            }
        end

    end
end
