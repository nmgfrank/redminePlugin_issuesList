# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/issues_list/related', :to => 'issues_list#related', :via => [:get, :post]
match '/issues_list/was_assigned_to_me', :to => 'issues_list#was_assigned_to_me', :via => [:get, :post]
