namespace :rubber do
	namespace :nsq do

		rubber.allow_optional_tasks(self)

		after "rubber:install_packages", "rubber:nsq:install"

    task :install, :roles => [:nsqd, :nsq_admin] do
      rubber.sudo_script 'install_nsq', <<-ENDSCRIPT
        if ! nsqd --version | grep "#{rubber_env.nsq_version}" &> /dev/null; then
          # Fetch the sources.
          wget https://s3.amazonaws.com/bitly-downloads/nsq/nsq-#{rubber_env.nsq_version}.linux-amd64.go#{rubber_env.nsq_go_version}.tar.gz
          tar -zxf nsq-#{rubber_env.nsq_version}.linux-amd64.go#{rubber_env.nsq_go_version}.tar.gz

          # Move the binaries to system folder.
          cd nsq-#{rubber_env.nsq_version}.linux-amd64.go#{rubber_env.nsq_go_version}
          cd bin
          cp * /usr/bin
          

          # create the user
          if ! id nsq &> /dev/null; then adduser --system --group nsq; fi

          # Clean up after ourselves.
          cd ../..
          rm -rf nsq-#{rubber_env.nsq_version}.linux-amd64.go#{rubber_env.nsq_go_version}
          rm nsq-#{rubber_env.nsq_version}.linux-amd64.go#{rubber_env.nsq_go_version}.tar.gz
        fi
      ENDSCRIPT
    end

		namespace :daemon do
			rubber.allow_optional_tasks(self)

			after "rubber:bootstrap", "rubber:nsq:daemon:bootstrap"

      task :bootstrap, :roles => :nsqd do
        exists = capture("echo $(ls /etc/nsqd.conf 2> /dev/null)")
        if exists.strip.size == 0
          rubber.update_code_for_bootstrap
          rubber.run_config(:file => "role/nsqd/", :force => true, :deploy_path => release_path)
          rsudo "mkdir -p /mnt/nsq"

          sleep 15 # Give nsqd a bit of time to start up.
        end
        restart
      end

			desc "Starts the NSQ daemons"
			task :start, :roles => :nsqd do
				rsudo "service nsqd start"
			end

			desc "Stops the NSQ daemons"
			task :stop, :roles => :nsqd do
				rsudo "service nsqd stop || true"
			end

			desc "Force stops the NSQ daemons"
			task :force_stop, :roles => :nsqd do
				rsudo "kill -9 `cat #{rubber_env.nsq_pid_file}"
			end

			desc "Restart the NSQ daemons"
			task :restart, :roles => :nsqd do
				stop
				start
			end
		end

		namespace :admin do
			rubber.allow_optional_tasks(self)

			after "rubber:bootstrap", "rubber:nsq:admin:bootstrap"

      task :bootstrap, :roles => :nsq_admin do
        exists = capture("echo $(ls /etc/nsqadmin.conf 2> /dev/null)")
        if exists.strip.size == 0
          rubber.update_code_for_bootstrap
          rubber.run_config(:file => "role/nsq_admin/", :force => true, :deploy_path => release_path)

          sleep 15 # Give nsqd a bit of time to start up.
        end
        restart
      end

			desc "Start the NSQ admin service"
			task :start, :roles => :nsq_admin do
				rsudo "service nsqadmin start"
			end

			desc "Stop the NSQ admin service"
			task :stop, :roles => :nsq_admin do
				rsudo "service nsqadmin stop || true"
			end

			desc "Force stop the NSQ admin service"
			task :force_stop, :roles => :nsq_admin do
				rsudo "kill -9 `cat #{nsq_lookupd_pid_file}"
			end

			desc "Restart the NSQ admin service"
			task :restart, :roles => :nsq_admin do
				stop
				start
			end
		end
	end
end