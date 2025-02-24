# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe InfoController do
  describe "GET 'health_check'" do
    it "works" do
      get 'health_check'
      expect(response).to be_successful
      expect(response.body).to eq 'canvas ok'
    end

    it "respond_toes json" do
      request.accept = "application/json"
      allow(Canvas).to receive(:revision).and_return("Test Proc")
      allow(Canvas::Cdn::RevManifest).to receive(:gulp_manifest).and_return({ test_key: "mock_revved_url" })
      get "health_check"
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to have_key('installation_uuid')
      json.delete('installation_uuid')
      expect(json).to eq({
                           "status" => "canvas ok",
                           "revision" => "Test Proc",
                           "asset_urls" => {
                             "common_css" => "/dist/brandable_css/new_styles_normal_contrast/bundles/common-#{BrandableCSS.cache_for('bundles/common', 'new_styles_normal_contrast')[:combinedChecksum]}.css",
                             "common_js" => ActionController::Base.helpers.javascript_url("#{ENV['USE_OPTIMIZED_JS'] == 'true' ? '/dist/webpack-production' : '/dist/webpack-dev'}/common"),
                             "revved_url" => "mock_revved_url"
                           }
                         })
    end
  end

  describe "GET 'health_prognosis'" do
    it "works if partitions are up to date" do
      # just in case
      Quizzes::QuizSubmissionEventPartitioner.process
      Version::Partitioner.process
      Messages::Partitioner.process

      get "health_prognosis"
      expect(response).to be_successful
    end

    it "fails if partitions haven't been running" do
      # stick a Version into last partition
      last_partition = CanvasPartman::PartitionManager.create(Version).partition_tables.last
      v_id = (last_partition.sub("versions_", "").to_i * Version.partition_size) + 1

      # don't have to make a real version anymore, just an object that _could_ make a version
      Course.create.wiki_pages.create!(:id => v_id, :title => "t")

      Timecop.freeze(4.years.from_now) do # and jump forward a ways
        get "health_prognosis"
        expect(response).to be_server_error
        body = response.body
        %w{messages_partition quizzes_submission_events_partition versions_partition}.each do |type|
          expect(body).to include(type)
        end
      end
    end
  end

  describe "GET 'readiness'" do
    it 'responds with 200 if all system components are alive and serving' do
      allow(Account.connection).to receive(:active?).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with('readiness').and_return(nil)
      allow(Delayed::Job.connection).to receive(:active?).and_return(true)
      get 'readiness'
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['status']).to eq 200
    end

    it 'responds with 503 if a system component is considered down' do
      allow(Account.connection).to receive(:active?).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with('readiness').and_return(nil)
      allow(Delayed::Job.connection).to receive(:active?).and_return(false)
      get 'readiness'
      expect(response.code).to eq '503'
      json = JSON.parse(response.body)
      expect(json['status']).to eq 503
    end

    it 'catches any exceptions thrown and log them as errors' do
      allow(Account.connection).to receive(:active?).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with('readiness').and_raise(Redis::TimeoutError)
      allow(Delayed::Job.connection).to receive(:active?).and_return(true)
      expect(Canvas::Errors).to receive(:capture_exception).once
      get 'readiness'
      expect(response.code).to eq '503'
      components = JSON.parse(response.body)['components']
      redis = components.find { |c| c['name'] == 'redis' }
      expect(redis['status']).to eq 503
    end

    it 'returns all dependent system components in json response' do
      allow(Account.connection).to receive(:active?).and_return(true)
      allow(MultiCache.cache).to receive(:fetch).and_call_original
      allow(MultiCache.cache).to receive(:fetch).with('readiness').and_return(nil)
      allow(Delayed::Job.connection).to receive(:active?).and_return(true)
      get 'readiness'
      expect(response).to be_successful
      components = JSON.parse(response.body)['components']
      expect(components.map { |c| c['name'] }).to eq %w[
        common_css common_js consul filesystem jobs postgresql redis rev_manifest vault
      ]
      expect(components.map { |c| c['status'] }).to eq [200, 200, 200, 200, 200, 200, 200, 200, 200]
    end
  end

  describe "GET 'help_links'" do
    it "works" do
      get 'help_links'
      expect(response).to be_successful
    end

    it "sets the locale for translated help link text from the current user" do
      user = User.create!(locale: 'es')
      user_session(user)
      # create and save account instance so that we don't invoke I18n's
      # localizer lambda in a request filter prior to loading necessary
      # users, accounts, context etc.
      Account.default
      get 'help_links'
      expect(I18n.locale.to_s).to eq 'es'
    end

    it "filters the links based on the current user's role" do
      account = Account.create!
      allow(account.help_links_builder).to receive(:default_links).and_return([
                                                                                {
                                                                                  :available_to => ['student'],
                                                                                  :text => 'Ask Your Instructor a Question',
                                                                                  :subtext => 'Questions are submitted to your instructor',
                                                                                  :url => '#teacher_feedback',
                                                                                  :is_default => 'true'
                                                                                },
                                                                                {
                                                                                  :available_to => ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
                                                                                  :text => 'Search the Canvas Guides',
                                                                                  :subtext => 'Find answers to common questions',
                                                                                  :url => 'https://community.canvaslms.test/t5/Canvas/ct-p/canvas',
                                                                                  :is_default => 'true'
                                                                                },
                                                                                {
                                                                                  :available_to => ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
                                                                                  :text => 'Report a Problem',
                                                                                  :subtext => 'If Canvas misbehaves, tell us about it',
                                                                                  :url => '#create_ticket',
                                                                                  :is_default => 'true'
                                                                                }
                                                                              ])
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
      admin = account_admin_user active_all: true
      user_session(admin)

      get 'help_links'
      links = json_parse(response.body)
      expect(links.select { |link| link[:text] == 'Ask Your Instructor a Question' }.size).to eq 0
    end
  end

  describe "GET 'web-app-manifest'" do
    it "works" do
      get 'web_app_manifest'
      expect(response).to be_successful
    end

    it "returns icon path correct" do
      get 'web_app_manifest'
      manifest = json_parse(response.body)
      src = manifest["icons"].first["src"]
      expect(src).to start_with("/dist/images/")
    end
  end
end
