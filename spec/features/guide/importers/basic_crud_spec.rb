require 'spec_helper'

describe "guide_importers", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :guide_node_guide, filename: "guide" }
  let(:index_path) { guide_importers_path site.id, node }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      within ".main-box" do
        expect(page).to have_css(".guide-importer")
      end
    end
  end
end
