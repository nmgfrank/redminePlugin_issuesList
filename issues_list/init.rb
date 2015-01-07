
Redmine::Plugin.register :issues_list do
  name 'Issues List plugin'
  author 'nmgfrank'
  description 'It offers different ways to view the issues list. 1. We can view the related issues more clearly. It finds the related issued and organizes them. '
  version '0.0.1'
  url 'http://nmgfrankblog.sinaapp.com'
  author_url 'http://nmgfrankblog.sinaapp.com'

  project_module :issues_list do
    permission :related_issues, 'issues_list'=>['related']
    permission :was_assigned_to_me_issues, 'issues_list'=>['was_assigned_to_me']
  end
  
  menu :project_menu, :issues_list, {:controller => 'issues_list', :action=>'related'},:caption=>:issues_list_project_button_label, :after => :issues, :param => :project_id

end
