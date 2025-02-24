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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe I18n do
  context "_core_en.js" do
    it "is up-to-date" do
      skip("Rails 6.0 specific") unless CANVAS_RAILS6_0
      translations = { 'en' => I18n.backend.send(:translations)[:en].slice(*I18nTasks::Utils::CORE_KEYS) }

      # HINT: if this spec fails, run `rake i18n:generate_js`...
      # it probably means you added a format or a new language
      expect(File.read('public/javascripts/translations/_core_en.js')).to eq(
        I18nTasks::Utils.dump_js(translations)
      )
    end
  end

  context "DontTrustI18nPluralizations" do
    it "does not raise an exception for a bad pluralization entry" do
      missing_other_key = { en: { __pluralize_test: { one: "One thing" } } }
      I18n.backend.stub(missing_other_key) do
        expect(I18n.t(:__pluralize_test, count: 123)).to eq ""
      end
    end
  end

  context "interpolation" do
    before { I18n.locale = I18n.default_locale }
    after { I18n.locale = I18n.default_locale }

    it "falls back to en if the current locale's interpolation is broken" do
      I18n.locale = :es
      I18n.backend.stub es: { __interpolation_test: "Hola %{mundo}" } do
        expect(I18n.t(:__interpolation_test, "Hello %{mundo}", { mundo: "WORLD" }))
          .to eq "Hola WORLD"
        expect(I18n.t(:__interpolation_test, "Hello %{world}", { world: "WORLD" }))
          .to eq "Hello WORLD"
      end
    end

    it "raises an error if the the en interpolation is broken" do
      expect {
        I18n.t(:__interpolation_test, "Hello %{world}", { foo: "bar" })
      }.to raise_error(I18n::MissingInterpolationArgument)
    end

    it "formats count numbers" do
      I18n.backend.stub(en: { __interpolation_test: { one: "One thing", other: "%{count} things" } }) do
        expect(I18n.t(:__interpolation_test,
                      one: "One thing",
                      other: "%{count} things",
                      count: 1001)).to eq "1,001 things"
      end
    end
  end

  context "genitives" do
    before { I18n.locale = I18n.default_locale }
    after { I18n.locale = I18n.default_locale }

    it "forms with `'s` in english" do
      I18n.locale = :en
      expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq ("Cody's")
    end

    it "forms with `s` in german generally" do
      I18n.locale = :de
      expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq ("Codys")
    end

    it "forms with `'` in german when ending appropriately" do
      I18n.locale = :de
      expect(I18n.form_proper_noun_singular_genitive("Max")).to eq ("Max'")
    end

    it "forms with `de ` in spanish" do
      I18n.locale = :es
      expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq ("de Cody")
    end

    it "returns it untouched in chinese" do
      I18n.locale = :"zh-Hant"
      expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq ("Cody")
    end
  end
end
