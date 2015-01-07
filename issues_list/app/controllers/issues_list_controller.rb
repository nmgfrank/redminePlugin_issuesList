class IssuesListController < ApplicationController
  unloadable
  
  
  def related
      _find_project
      _filter_init
      
      @relation_types = []
      
      sql = "SELECT relation_type FROM issue_relations as ir left join issues as ai on ai.id = ir.issue_from_id left join issues as bi on bi.id = ir.issue_to_id where ai.project_id in #{@project_ids_str} or bi.project_id in #{@project_ids_str} group by relation_type"
      results = ActiveRecord::Base.connection.select_all(sql)
      results.each do |result|
        @relation_types.push(result['relation_type'])
      end
      
      @selected_relation_types = params['selected_relation_types']
      if @selected_relation_types.blank? && @relation_types.length > 0
          @selected_relation_types = [@relation_types[0]]
      end
      
      if !@selected_relation_types.blank?
          selected_relation_types_str = "("
          @selected_relation_types.each do |rtype|
            selected_relation_types_str += "'#{rtype}',"
          end
          selected_relation_types_str = selected_relation_types_str[0,selected_relation_types_str.length - 1]
          selected_relation_types_str += ")"
          
          sql = "SELECT relation_type,issue_from_id, issue_to_id,from_i.project_id as from_project_id, to_i.project_id as to_project_id, from_i.subject as from_subject, to_i.subject as to_subject, from_p.name as from_project, to_p.name as to_project, from_is.name as from_status, to_is.name as to_status FROM issue_relations as ir left join issues as from_i on from_i.id = ir.issue_from_id left join issues as to_i on to_i.id = ir.issue_to_id  left join projects as from_p on from_p.id = from_i.project_id left join projects as to_p on to_p.id = to_i.project_id left join issue_statuses as from_is on from_is.id = from_i.status_id left join issue_statuses as to_is  on to_is.id = to_i.status_id where (from_i.project_id in #{@project_ids_str} or to_i.project_id in #{@project_ids_str}) and relation_type in #{selected_relation_types_str}"
          
          results =  ActiveRecord::Base.connection.select_all(sql)
          
          @group_panel = Hash.new
          @issue_hash = Hash.new
          
          
          results.each do |relation|
              relation_type = relation['relation_type']
              issue_from_id = relation['issue_from_id']
              issue_to_id = relation['issue_to_id']
              from_project_id = relation['from_project_id']
              to_project_id = relation['to_project_id']
              from_subject = relation['from_subject']
              to_subject = relation['to_subject']
              from_project = relation['from_project']
              to_project = relation['to_project']  
              from_status = relation['from_status']
              to_status = relation['to_status']
              
              
              is_exists_in_one_subgroup = false
              is_exists_in_two_subgroup = false
              first_subgroup = nil
              second_subgroup = nil
              if !@issue_hash.has_key? issue_to_id
                 @issue_hash[issue_to_id] = {:subject=>to_subject, :project=> to_project,:status=>to_status}
              end
              if !@issue_hash.has_key? issue_from_id
                 @issue_hash[issue_from_id] = {:subject=>from_subject, :project => from_project, :status=>from_status}
              end
              
              if !@group_panel.has_key? relation_type
                @group_panel[relation_type] = []
              end
              
              @group_panel[relation_type].each do |subgroup|
                if (subgroup.include? issue_from_id) || (subgroup.include? issue_to_id)
                    if is_exists_in_one_subgroup == true
                         is_exists_in_two_subgroup = true
                         second_subgroup = subgroup  
                         break 
                    end
                    if is_exists_in_one_subgroup == false
                        is_exists_in_one_subgroup = true
                        first_subgroup = subgroup
                    end
                end 
              end
              
              if is_exists_in_two_subgroup
                second_subgroup.each do |issue_id|
                    first_subgroup.push(issue_id)
                end
                first_subgroup.push(issue_from_id)
                first_subgroup.push(issue_to_id)
                
                
                @group_panel.delete(second_subgroup)
              
              elsif is_exists_in_one_subgroup
                first_subgroup.push(issue_from_id)
                first_subgroup.push(issue_to_id) 
              else
                   @group_panel[relation_type].push([issue_from_id,issue_to_id])          
              end     
          
          end 
      end
  end
  
  
  def was_assigned_to_me
      _find_project
      _filter_init
      
      user_id = User.current.id
      
      @issues = []
      
      if !@tracker_ids.blank?
          sql = "select DATE_FORMAT(update_time, '%Y-%m-%d %H:%i') as latest_time, issue_id, from_lastname,from_firstname, to_lastname,to_firstname ,subject, issue_id from (select i.id as issue_id, from_u.lastname as from_lastname, from_u.firstname as from_firstname, to_u.lastname as to_lastname, to_u.firstname as to_firstname, j.created_on as update_time , i.subject as subject  from issues as i left join journals as j on i.id = j.journalized_id left join journal_details as jd on jd.journal_id = j.id left join users as from_u on from_u.id = jd.old_value left join users as to_u on jd.value = to_u.id  where i.project_id in #{@project_ids_str} and i.tracker_id in #{@tracker_ids_str} and i.assigned_to_id != #{user_id} and  prop_key = 'assigned_to_id' and (old_value = '#{user_id}' or value = '#{user_id}')  order by j.created_on desc ) as temp group by issue_id order by latest_time desc limit 5000"
          Rails.logger.info sql
          
          results =  ActiveRecord::Base.connection.select_all(sql)
          @issues = results
      end
  
      
  
  end
  
 

private

    def _find_project
        @project = Project.find(params[:project_id])
    
    end

    # general private method
    def _filter_init
        @action = self.action_name
       
    
        @project_ids = params['selected_project_ids']
        if @project_ids.blank?
            @project_ids = [@project.id.to_s]
        end
        project_ids_str = "("
        @project_ids.each do |pro_id|
            project_ids_str += pro_id + ","
        end
        @project_ids_str = project_ids_str[0,project_ids_str.length - 1]
        @project_ids_str += ")"

        @issue_tracker_array = Issue.find_by_sql("select name,id from trackers where id in (select tracker_id from issues where project_id in #{@project_ids_str} group by tracker_id )")
        
        
        @tracker_ids = params['selected_tracker_ids']
        
        if @tracker_ids.nil? || @tracker_ids.blank?
            if @issue_tracker_array.length > 0
                @tracker_ids = [@issue_tracker_array[0].attributes['id'].to_s]
                tracker_ids_str = "("
                @tracker_ids.each do |tr_id|
                    tracker_ids_str += tr_id + ","
                end
                @tracker_ids_str = tracker_ids_str[0,tracker_ids_str.length - 1]
                @tracker_ids_str += ")"                
            else 
                @tracker_ids = []
                @tracker_ids_str = ""
            end
        else
            tracker_ids_str = "("
            @tracker_ids.each do |tr_id|
                tracker_ids_str += tr_id + ","
            end
            @tracker_ids_str = tracker_ids_str[0,tracker_ids_str.length - 1]
            @tracker_ids_str += ")" 
        end 
          
    
    end 
  

end
