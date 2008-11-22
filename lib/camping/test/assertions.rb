module Camping::TestUtils::Assertions
  def assert_response(status_code, msg = "Status should be #{status_code}, was #{@response.status}")
    case status_code
    when Symbol
      meth = "#{status_code}?".to_sym
      raise "#{status_code} is not a valid response" unless @response.respond_to?(meth)
      assert @response.send(meth), msg
    when Integer
      assert_equal status_code, @response.status
    end
  end
  
  def assert_match_body(regex, message=nil)
    assert_match regex, @response.body, message
  end

  def assert_no_match_body(regex, message=nil)
    assert_no_match regex, @response.body, message
  end
  
  def assert_cookie(name, pat, message=nil)
    assert_match pat, @cookies[name].to_s, message
  end
  
  def assert_session(name, pat, message=nil)
    assert_match pat, @state[name].to_s, message
  end
  
  def assert_sessions
    assert @state
  end
  
  def assert_no_sessions
    assert_nil @state
  end
  
  # Asserts that it's possible to follow a redirect before it does it.
  def follow_redirect!
    assert @response, "No response made"
    assert_response :redirect, "No redirect made"
    follow_redirect
  end
  
  def assert_redirected_to(url, msg = "Should redirect to #{url}")
    assert_response :redirect
    assert_equal url, extract_redirect, msg
  end
end