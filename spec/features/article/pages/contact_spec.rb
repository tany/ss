require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:item) { create(:article_page, cur_node: node) }
  let!(:new_path) { new_article_page_path site.id, node }
  let!(:contact_group) { create(:contact_group, name: "contact_group") }

  context "contact" do
    before { login_cms_user }
    before { site.add_to_set group_ids: contact_group.id }

    it do
      visit new_path

      within '#addon-contact-agents-addons-page' do
        wait_addon_open do
          first('.toggle-head').click
        end

        within '.toggle-body' do
          first('.ajax-box').click
        end
      end

      wait_for_cbox do
        click_on "contact_group"
      end

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      click_on I18n.t("ss.buttons.ignore_alert")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      section = first('#addon-contact-agents-addons-page')
      expect(section).to have_text(contact_group.name)
      expect(section).to have_text(contact_group.contact_tel)
      expect(section).to have_text(contact_group.contact_fax)
      expect(section).to have_text(contact_group.contact_email)
      expect(section).to have_text(contact_group.contact_link_url)
      expect(section).to have_text(contact_group.contact_link_name)
    end
  end
end
