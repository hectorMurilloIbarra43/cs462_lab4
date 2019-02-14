ruleset wovyn_base {
    meta {
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                 auth_token  = keys:twilio{"auth_token"}

    }
    global{
        temperature_threshold = 90                    
        to = 7633505859
        from = 17634529729
    }
    rule hearbeat{
        select when wovyn heartbeat
        pre {
                isGenericThing = (event:attr("GenericThing") != "")
                            //if true            grab the temp
                temperatur = (isGenericThing) => event:attr("temperature") | null
                //z = (x > y) => y | x
        }
        if isGenericThing then 
            every {
                send_directive("response", {"temperature": temperature})
                send_directive("response", {"isGenericThing":isGenericThing})
            }
            fired {
                now = time:now();
                raise wovyn event "new_temperature_reading"
                    attributes {"temperature": temperature, "timestamp":now}
            }
    }
    rule find_high_temps{
        select when wovyn new_temperature_reading
        pre{
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
        }
        if temperature > temperature_threshold then
            send_directive("there was a threshold violation")
        fired {
            raise wovyn event "threshold_violation"
                attributes {"temperature":temperature, "timestamp":timestamp}
        }
        else{
            // nothing here i suppose
        }
    }
    rule threshold_notification{
        select when wovyn threshold_violation
        pre{
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
        }
        every{
            twilio:send_sms(to,
                            from,
                            "WARNING: GPU temperature is " + temerature + "C: exceeding threshold of " + temperature_threshold)
            send_directive("WARNING: GPU temperature is " + temerature + "C: exceeding threshold of " + temperature_threshold)
        }

    }
}


