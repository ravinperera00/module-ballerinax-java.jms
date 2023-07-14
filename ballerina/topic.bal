// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;

# Represent the JMS topic.
public class Topic {
    *Destination;

    # Initialized a `Topic` object.
    #
    # + handle - The java reference to the jms text message.
    function init(handle topic) {
        self.jmsDestination = topic;
    }

    # Get the JMS topic
    #
    # + return - Returns the java reference to the jms topic
    function getJmsDestination() returns handle {
        return self.jmsDestination;
    }

    # Gets the name of this topic.
    #
    # + return - Returns the string value or an error if it fails.
    public function getTopicName() returns string|error? {
        handle topic = check getTopicName(self.jmsDestination);
        return java:toString(topic);
    }
}

function getTopicName(handle destination) returns handle|error = @java:Method {
    'class: "javax.jms.Topic"
} external;
