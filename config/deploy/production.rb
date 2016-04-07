set :linked_files, fetch(:linked_files, []).push(*%w{config/production.sphinx.conf})

before 'deploy:assets:precompile', 'deploy:assets:generate_custom_css'
after 'deploy:restart', 'thinking_sphinx:stop'
after 'deploy:restart', 'thinking_sphinx:index'
after 'deploy:restart', 'thinking_sphinx:start'
#after 'deploy:restart', 'delayed_job:restart'

namespace :deploy do
  namespace :assets do
    task :generate_custom_css do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, 'sharetribe:generate_customization_stylesheets_immediately'
          end
        end
      end
    end
  end
end
