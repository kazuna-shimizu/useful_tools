module BackLog
  class Task
    #constants
    ENDPOINT = "issues"
    #accessor
    attr_accessor :id,
                  :name,
                  :assigned_user_id,
                  :created_user_id,
                  :project_id,
                  :mile_stone_id,
                  :parenet_id,
                  :estimated_hour,
                  :created_at,
                  :actual_hour,
                  :start_date,
                  :due_date,
                  :kpi,
                  :type_id
    #constructor
    def initialize(id:, name:, assigned_user_id:, created_user_id:, project_id:, mile_stone_id:, parenet_id:, estimated_hour:, actual_hour: ,created_at:, start_date:, due_date:, type_id:)
      @id = id
      @name = name
      @assigned_user_id = assigned_user_id
      @created_user_id = created_user_id
      @project_id = project_id
      @mile_stone_id = mile_stone_id
      @parenet_id = parenet_id
      @estimated_hour = estimated_hour
      @actual_hour = actual_hour
      @created_at = created_at
      @start_date = start_date.nil? ? Time.now : Time.parse(start_date)
      @due_date = due_date.nil? ? Time.now : Time.parse(due_date)
      @type_id = type_id
    end

    #class method
    #look this url what parameters are allowed(http://developer.nulab-inc.com/ja/docs/backlog/api/2/get-issues)
    #parameters hash's keys should be stirng not symbol here
    #the limit of tasks per request is 20(default) to 100, so you migth miss some tasks when the conditions aren't that specific
    def self.find(params)
      params.merge!({order: "asc"})
      tasks_infos = JSON.parse( BackLog::Base.http_get(BackLog::Task::ENDPOINT, params) , {:symbolize_names => true} )
      tasks = tasks_infos.map do |task_info|
         BackLog::Task.new(id: task_info[:id],
                           name: task_info[:summary],
                           assigned_user_id: task_info[:assignee][:id].to_i,
                           created_user_id: task_info[:createdUser][:id],
                           project_id: task_info[:projectId],
                           mile_stone_id: task_info[:milestone].empty? ? 0 : task_info[:milestone].first[:id],
                           parenet_id: task_info[:parentIssueId].to_i,
                           estimated_hour: task_info[:estimatedHours].to_f,
                           actual_hour: task_info[:actualHours].to_f,
                           created_at: Time.parse(task_info[:created]),
                           start_date: task_info[:startDate],
                           due_date: task_info[:dueDate],
                           type_id: task_info[:issueType][:id]
                          )
      end
    end

    def self.create
    end

    def self.count_number
    end

    #instance method
    def update
    end

    def delete
    end

    def show
    end

    def calculate_kpi(calculate_time: Time.now)
      calclated_kpi = estimated_hour.to_f * self.point_coefficient * self.penalty_of_wrong_expect * self.penalty_of_delay( calculate_time )
      @kpi = calclated_kpi
    end

    def type
      BackLog::Type.find(self.type_id)
    end

    def point_coefficient
      case type.name
        when "hotfix"
          3.0
        when "bugfix", "調査", "機能改善", "企画", "設計", "開発", "ソースレビュー", "テスト", "デザイン", "UI / UX", "マネジメント", "ディレクション"
          2.5
        when "ルーティーン", "その他"
          1.3
        else
          2.0
      end
    end

    def penalty_of_wrong_expect
      unless estimated_hour.to_i == 0 && actual_hour.to_i == 0
        estimated_hour > actual_hour ? 0.9 : 1
      else
        1
      end
    end

    def penalty_of_delay( calculate_time )
     unless due_date.nil?
       calculate_time > due_date ? 0.9 : 1
     else
       1
     end
    end
  end
end
