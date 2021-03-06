module SS::AjaxFileFilter
  extend ActiveSupport::Concern

  included do
    layout "ss/ajax"
  end

  private

  def append_view_paths
    append_view_path "app/views/ss/crud/ajax_files"
    super
  end

  def select_with_clone
    set_item
    return render(json: [I18n.t('ss.errors.sanitizer.wait')], status: 500) if @item.sanitizer_state == 'wait'

    @item = @item.copy(
      cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node
    )
    @page = Cms::Page.find_or_initialize_by(id: params[:owner_item_id])
    @page = @page.becomes_with_route(params[:owner_item_type].underscore) if params[:owner_item_type].present?

    render file: :select, layout: !request.xhr?
  end

  public

  def index
    @items = @model
    @items = @items.site(@cur_site) if @cur_site
    @items = @items.allow(:read, @cur_user).
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def select
    set_item
    @page = Cms::Page.find_or_initialize_by(id: params[:owner_item_id])
    @page = @page.becomes_with_route(params[:owner_item_type].underscore) if params[:owner_item_type].present?
    render file: :select, layout: !request.xhr?
  end
end
