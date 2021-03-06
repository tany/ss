require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:approve_comment) { "approve-#{unique_id}" }
  let(:line_text_message) { unique_id }

  context "approve and publish" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
    end

    context "post none" do
      it "#edit" do
        capture_line_bot_client do |capture|
          # edit
          login_cms_user
          visit edit_path

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.expired"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          # send request
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_cbox_open do
              click_on I18n.t("workflow.search_approvers.index")
            end
          end

          wait_for_cbox do
            expect(page).to have_content(user1.long_name)
            wait_cbox_close do
              click_on user1.long_name
            end
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          # approve
          login_user user1
          visit show_path
          within ".mod-workflow-approve" do
            expect(page).to have_no_css(".sns-post-confirm", text: I18n.t("cms.confirm.line_post_enabled"))
            fill_in "remand[comment]", with: approve_comment
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
            expect(page).to have_css(".index", text: approve_comment)
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0
        end
      end
    end

    context "post message_only_carousel" do
      it "#edit" do
        capture_line_bot_client do |capture|
          # edit
          login_cms_user
          visit edit_path

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          # send request
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_cbox_open do
              click_on I18n.t("workflow.search_approvers.index")
            end
          end

          wait_for_cbox do
            expect(page).to have_content(user1.long_name)
            wait_cbox_close do
              click_on user1.long_name
            end
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          # approve
          login_user user1
          visit show_path
          within ".mod-workflow-approve" do
            expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.line_post_enabled"))
            fill_in "remand[comment]", with: approve_comment
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
            expect(page).to have_css(".index", text: approve_comment)
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end

      # with branch page
      it "#edit" do
        capture_line_bot_client do |capture|
          # create branch
          login_cms_user
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(page).to have_link I18n.t("ss.links.edit")

          # edit
          click_on I18n.t("ss.links.edit")
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          # send request
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_cbox_open do
              click_on I18n.t("workflow.search_approvers.index")
            end
          end

          wait_for_cbox do
            expect(page).to have_content(user1.long_name)
            wait_cbox_close do
              click_on user1.long_name
            end
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          # approve
          login_user user1
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end

          within ".mod-workflow-approve" do
            expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.line_post_enabled"))
            fill_in "remand[comment]", with: approve_comment
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
            expect(page).to have_css(".index", text: approve_comment)
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end
    end
  end
end
