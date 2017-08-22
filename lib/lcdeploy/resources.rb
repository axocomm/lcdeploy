module LCD
  # For now this is just going to be generating lines of bash to run
  # either locally or over SSH.
  #
  # Maybe eventually they will actually be smarter, but for now this
  # is fine.
  class Resources
    def self.create_directory(dir, params = {})
      user = params[:user]
      group = params[:group]
      mode = params[:mode]

      cmd = []
      cmd << "mkdir #{dir}"
      if user and group
        cmd << "chown #{user}:#{group} #{dir}"
      elsif user
        cmd << "chown #{user} #{dir}"
      elsif group
        cmd << "chown :#{group} #{dir}"
      end

      if mode
        cmd << "chmod #{mode.to_base(8)} #{dir}"
      end

      cmd.join(' && ')
    end

    def self.clone_repository(source, params = {})
      to = params[:to] or raise "'to' parameter is required"
      user = params[:user] || 'root'
      branch = params[:branch] || 'master'

      self.as_user user, "git clone -b #{branch} #{source} #{to}"
    end

    def self.build_docker_image(name, params = {})
      path = params[:path] || '.'
      tag = params[:tag] || 'latest'

      "docker build -t #{name}:#{tag} #{path}"
    end

    def self.run_docker_container(name, params = {})
      image = params[:image] or fail "'image' is required"
      ports = params[:ports]
      volumes = params[:volumes]

      cmd = []
      cmd << "docker run -d --name=#{name}"

      if ports
        cmd << ports.map do |pd|
          ps = pd.is_a?(Array) ? pd.join(':') : pd
          "-p #{ps}"
        end.join(' ')
      end

      if volumes
        cmd << volumes.map do |vd|
          "-v #{vd.join(':')}"
        end.join(' ')
      end

      cmd << image
      cmd.join(' ')
    end

    def self.put_file(destination, params = {})
      source = params[:source] or fail "'source' is required"  # TODO: content
      host = params[:ssh_host] or fail "'host' is required"
      port = params[:ssh_port] || 22
      user = params[:user]

      host_str = user.nil? ? host : "#{user}@#{host}"
      "scp -P #{port} #{source} #{host_str}:#{destination}"
    end

    def self.as_user(user, command)
      "sudo -u #{user} #{command}"
    end
  end
end
