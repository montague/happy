require 'spec_helper'

module Happy
  describe Controller::Actions do
    subject { Controller.new }

    describe '#serve!' do
      def app
        Happy.route do
          on('simple') { serve! "Simple response" }
          on('with_headers') { serve! "body { color: red }", :content_type => 'text/css' }
          on('with_status')  { serve! "Not Allowed", :status => 401 }
          on('with_layout')  { serve! "content", :layout => 'layout.erb' }
        end
      end

      it "serves the provided string as the response body" do
        response_for { get '/simple' }.body.should == 'Simple response'
      end

      it "responds with a status code of 200 by default" do
        response_for { get '/simple' }.status.should == 200
      end

      it "sets the response status code to its :status option" do
        response_for { get '/with_status' }.status.should == 401
      end

      it "uses the layout provided through the :layout option" do
        instance = Controller.new
        instance.should_receive(:render).with('layout.erb')

        catch(:done) { instance.serve! "content", :layout => 'layout.erb' }
      end

      it "sets extra options as response headers" do
        response_for { get '/with_headers' }['Content-type'].should == 'text/css'
      end

      it "finishes the rendering by throwing :done" do
        expect { subject.serve! "body" }.to throw_symbol :done
      end

      it "doesn't do anything if the current path does not match the request path" do
        def app
          Happy.route do
            serve! "This should not render"
            on 'test' do
              serve! "But this should render"
            end
          end
        end

        response_for { get '/test' }.body.should == "But this should render"
      end
    end

    describe '#redirect!' do
      it "triggers a redirection to the specified URL" do
        def app
          Happy.route { redirect! 'http://www.test.com' }
        end

        get '/'
        last_response.status.should == 302
        last_response.headers['Location'].should == 'http://www.test.com'
      end

      it "sets the provided status code" do
        def app
          Happy.route { redirect! 'http://www.test.com', 301 }
        end

        get '/'
        last_response.status.should == 301
      end

      it "doesn't do anything if the current path does not match the request path" do
        def app
          Happy.route do
            redirect! "http://mans.de"

            on 'test' do
              redirect! "http://schnitzelpress.org"
            end
          end
        end

        get '/test'
        last_response.should be_redirect
        last_response.headers['Location'].should == 'http://schnitzelpress.org'
      end
    end

    describe '#run' do
      it "passes control to another controller" do
        class InnerController < Controller
          def route
            'awesome!'
          end
        end

        def app
          Happy.route { run InnerController }
        end

        response_for { get '/' }.body.should == 'awesome!'
      end

      it "passes control to a Rack app" do
        class SomeRackApp
          def self.call(env)
            Rack::Response.new('racksome!')
          end
        end

        def app
          Happy.route { run SomeRackApp }
        end

        response_for { get '/' }.body.should == 'racksome!'
      end

      it "falls back to .to_s" do
        class SomeClass
          def self.to_s
            "stringsome!"
          end
        end

        def app
          Happy.route { run SomeClass }
        end

        response_for { get '/' }.body.should == 'stringsome!'
      end
    end

    describe '#header' do
      it "sets the specified header in the response" do
        subject.send(:response).should_receive(:[]=).with('Content-type', 'text/css')
        subject.header 'Content-type', 'text/css'
      end

      it "also accepts the header name as a symbol" do
        subject.send(:response).should_receive(:[]=).with('Content-type', 'text/css')
        subject.header :content_type, 'text/css'
      end
    end

    describe '#content_type' do
      it "sets the Content-type header" do
        subject.should_receive(:header).with(:content_type, 'text/css')
        subject.content_type 'text/css'
      end
    end

    describe '#layout' do
      it "sets the layout to be used by the current context" do
        subject.send(:response).should_receive(:layout=).with('layout.erb')
        subject.layout 'layout.erb'
      end
    end
  end
end
