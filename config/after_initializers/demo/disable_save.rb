ApplicationController.class_eval do
  before_action :disable_save_on_demo

  private

  def disable_save_on_demo
    if request.put? && request.path =~ /user|group|site/
      render plain: "デモデータのため更新できません。"
    elsif request.delete?
      render plain: "デモデータのため削除できません。"
    end
  end
end
