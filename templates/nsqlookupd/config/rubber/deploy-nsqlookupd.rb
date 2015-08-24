namespace :rubber do
	namespace :nsq do

		rubber.allow_optional_tasks(self)

		namespace :lookupd do
			rubber.allow_optional_tasks(self)

			before "deploy:stop", "rubber:nsq:lookupd:stop"
			after "deploy:start", "rubber:nsq:lookupd:start"
			after "deploy:restart", "rubber:nsq:lookupd:restart"

			after "rubber:install_packages", "rubber:nsq:lookupd:install"

	    task :install, :roles => :nsqlookupd do
	      rubber.sudo_script 'install_redis', <<-ENDSCRIPT
	        if ! nsqlookupd --version | grep "#{rubber_env.nsq_version}" &> /dev/null; then
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

			task :bootstrap, :roles => :nsqlookupd do
        exists = capture("echo $(ls /etc/nsqlookupd.conf 2> /dev/null)")
        if exists.strip.size == 0
          rubber.update_code_for_bootstrap
          rubber.run_config(:file => "role/nsqlookupd/", :force => true, :deploy_path => release_path)

          restart
          sleep 15 # Give nsqd a bit of time to start up.
        end
      end

			desc "Start the NSQ lookup daemon"
			task :start, :role => :nsqlookupd do
				rsudo "service nsqlookupd start"
			end

			desc "Stop the NSQ lookup daemon"
			task :stop, :role => :nsqlookupd do
				rsudo "service nsqlookupd stop || true"
			end

			desc "Force stop the NSQ lookup daemon"
			task :force_stop, :role => :nsqlookupd do
				rsudo "kill -9 `cat #{nsq_lookupd_pid_file}"
			end

			desc "Restart the NSQ lookup daemon"
			task :restart, :role => :nsqlookupd do
				stop
				start
			end
		end
	end
end