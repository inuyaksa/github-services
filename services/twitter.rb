class Service::Twitter < Service
  string  :token, :secret, :hashtag
  boolean :digest

  def receive_push
    return unless payload['commits']

    statuses   = []
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      tiny_url = shorten_url("#{payload['repository']['url']}/commits/#{ref_name}")      
      msg = "[#{repository}] #{tiny_url} #{author['name']} - #{payload['commits'].length} commits"      
      hash = ""
      if data['hashtag'] != ''
        hash = " #" + data['hashtag']
      status = msg
      maxlen = 138 - hash.length
      status.length >= maxlen ? statuses << msg[0..(maxlen-4)] + '...' + hash : statuses << status
    else
      payload['commits'].each do |commit|
        author = commit['author'] || {}
        tiny_url = shorten_url(commit['url'])
        msg = "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
        hash = ""
        if data['hashtag'] != ''
          hash = " #" + data['hashtag']
        status = msg
        maxlen = 138 - hash.length        
        status.length >= maxlen ? statuses << msg[0..(maxlen-4)] + '...' + hash : statuses << status
      end
    end

    statuses.each do |status|
      post(status)
    end
  end

  def post(status)
    params = { 'status' => status, 'source' => 'github' }

    access_token = ::OAuth::AccessToken.new(consumer, data['token'], data['secret'])
    consumer.request(:post, "/1/statuses/update.json",
                     access_token, { :scheme => :query_string }, params)
  end

  def consumer_key
    secrets['twitter']['key']
  end

  def consumer_secret
    secrets['twitter']['secret']
  end

  def consumer
    @consumer ||= ::OAuth::Consumer.new(consumer_key, consumer_secret,
                                        {:site => "http://api.twitter.com"})
  end
end
