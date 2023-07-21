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

import ballerina/log;
import ballerina/jballerina.java;

# Represents the JMS session.
#
# + config - Stores the configurations related to a JMS session.
public isolated client class Session {
    private final readonly & SessionConfiguration config;
    private final handle jmsSession;

# The default constructor of the JMS session.
    public isolated function init(handle jmsConnection, SessionConfiguration sessionConfig) returns error? {
        self.config = sessionConfig.cloneReadOnly();
        handle ackModeJString = java:fromString(self.config.acknowledgementMode);
        self.jmsSession = check createJmsSession(jmsConnection, ackModeJString);
    }

    # Unsubscribe a durable subscription that has been created by a client.
    # It is erroneous for a client to delete a durable subscription while there is an active (not closed) consumer
    # for the subscription, or while a consumed message being part of a pending transaction or has not been
    # acknowledged in the session.
    #
    # + subscriptionId - The name, which is used to identify the subscription.
    # + return - Cancels the subscription.
    isolated remote function unsubscribe(string subscriptionId) returns error? {
        return unsubscribeJmsSubscription(self.jmsSession, java:fromString(subscriptionId));
    }

    # Creates a JMS Queue, which can be used as temporary response destination.
    #
    # + return - Returns the JMS destination for a temporary queue or an error if it fails.
    isolated remote function createTemporaryQueue() returns Destination|Error {
        handle|error val = createTemporaryJmsQueue(self.jmsSession);
        if (val is handle) {
            return new TemporaryQueue(val);
        } else {
            return error Error("Error occurred while creating the JMS queue.", val);
        }
    }

    # Creates a JMS Topic, which can be used as a temporary response destination.
    #
    # + return - Returns the JMS destination for a temporary topic or an error if it fails.
    isolated remote function createTemporaryTopic() returns Destination|Error {
        handle|error val = createTemporaryJmsTopic(self.jmsSession);
        if (val is handle) {
            return new TemporaryTopic(val);
        } else {
            return error Error("Error occurred while creating the JMS topic.", val);
        }
    }

    # Creates a JMS Queue, which can be used with a message producer.
    #
    # + queueName - The name of the Queue.
    # + return - Returns the JMS destination for a queue or an error if it fails.
    isolated remote function createQueue(string queueName) returns Destination|error {
        handle|error val = createJmsQueue(self.jmsSession, java:fromString(queueName));
        if (val is handle) {
            return new Queue(val);
        } else {
            return val;
        }
    }

    # Creates a JMS Topic, which can be used with a message producer.
    #
    # + topicName - The name of the Topic.
    # + return - Returns the JMS destination for a topic or an error if it fails.
    isolated remote function createTopic(string topicName) returns Destination|error {
        handle|error val = createJmsTopic(self.jmsSession, java:fromString(topicName));
        if (val is handle) {
            return new Topic(val);
        } else {
            return val;
        }
    }

    # Get the reference to the java session object.
    #
    # + return - Returns jms session java reference.
    function getJmsSession() returns handle {
        return self.jmsSession;
    }

    # Creates a JMS message.
    #
    # + return - Returns the JMS message or an error if it fails.
    public function createMessage() returns Message|error {
        handle|error val = createJmsMessage(self.jmsSession);
        if (val is handle) {
            Message message = new(val);
            return message;
        } else {
            return val;
        }
    }

    # Creates a JMS text message.
    #
    # + text - The string used to initialize this message
    # + return - Returns the JMS text message or an error if it fails.
    public function createTextMessage(string? text = ()) returns TextMessage|error {
        if (text is string) {
            handle|error val = createJmsTextMessageWithText(self.jmsSession, java:fromString(text));
            if (val is handle) {
                TextMessage textMessage = new(val);
                return textMessage;
            } else {
                return val;
            }
        } else {
            handle|error val = createJmsTextMessage(self.jmsSession);
            if (val is handle) {
                TextMessage textMessage = new(val);
                return textMessage;
            } else {
                return val;
            }
        }
    }

    # Creates a JMS map message.
    #
    # + return - Returns the JMS map message or an error if it fails.
    public function createMapMessage() returns MapMessage|error {
        handle|error val = createJmsMapMessage(self.jmsSession);
        if (val is handle) {
            MapMessage message = new(val);
            return message;
        } else {
            return val;
        }
    }

    # Creates a JMS stream message.
    #
    # + return - Returns the JMS stream message or an error if it fails.
    public function createStreamMessage() returns StreamMessage|error {
        handle|error val = createJmsStreamMessage(self.jmsSession);
        if (val is handle) {
            StreamMessage message = new(val);
            return message;
        } else {
            return val;
        }
    }

    # Creates a JMS byte message.
    #
    # + return - Returns the JMS byte message or an error if it fails.
    public function createByteMessage() returns BytesMessage|error {
        handle|error val = createJmsBytesMessage(self.jmsSession);
        if (val is handle) {
            BytesMessage message = new(val);
            return message;
        } else {
            return val;
        }
    }

    # Creates a MessageProducer to send messages to the specified destination.
    #
    # + destination - the Destination to send to, or nil if this is a producer which does not have a specified destination
    # + return - Returns jms:MessageProducer
    public function createProducer(Destination? destination = ()) returns MessageProducer|error {

        handle jmsDestination = (destination is Destination) ? destination.getJmsDestination(): JAVA_NULL;
        handle|error v = createJmsProducer(self.jmsSession, jmsDestination);
        if (v is handle) {
            return new MessageProducer(v, self.jmsSession);
        } else {
            log:printError("Error occurred while creating producer");
            return v;
        }
    }

    # Creates a MessageConsumer for the specified destination. Both Queue and Topic can be used in 
    # the destination parameter to create a MessageConsumer.
    #
    # + destination - the Destination to access 
    # + messageSelector - only messages with properties matching the message selector expression are delivered. 
    #                     An empty string indicates that there is no message selector for the message consumer.
    # + noLocal - if true, and the destination is a topic, then the MessageConsumer will not receive messages published to the topic by its own connection.
    # + return - Returns a jms:MessageConsumer
    isolated remote function createConsumer(Destination destination, string messageSelector = "",
                                          boolean noLocal = false) returns MessageConsumer|error {
        var val = createJmsConsumer(self.jmsSession, destination.getJmsDestination(),
                                    java:fromString(messageSelector), noLocal);
        if (val is handle) {
            MessageConsumer consumer = new(val);
            return consumer;
        } else {
            return val;
        }
    }

    # Creates an unshared durable subscription on the specified topic (if one does not already exist), 
    # specifying a message selector and the noLocal parameter, and creates a consumer on that durable subscription. 
    #
    # + topic - the non-temporary Topic to subscribe to 
    # + subscriberName - the name used to identify this subscription
    # + messageSelector - only messages with properties matching the message selector expression are added to the durable subscription. 
    #                     An empty string indicates that there is no message selector for the durable subscription.
    # + noLocal - if true then any messages published to the topic using this session's connection, or any other connection 
    #             with the same client identifier, will not be added to the durable subscription.
    # + return - Returns a jms:MessageConsumer
    remote function createDurableSubscriber(Destination topic, string subscriberName,
                                                   string messageSelector = "",
                                                   boolean noLocal = false) returns MessageConsumer|error {
        var val = createJmsDurableSubscriber(self.jmsSession, topic.getJmsDestination(),
                                             java:fromString(subscriberName),
                                             java:fromString(messageSelector), noLocal);
        if (val is handle) {
            MessageConsumer consumer = new(val);
            return consumer;
        } else {
            return val;
        }
    }

    # Creates a shared non-durable subscription with the specified name on the specified topic 
    # (if one does not already exist) specifying a message selector, and creates a consumer on that subscription. 
    #
    # + topic - the Topic to subscribe to
    # + subscriberName - the name used to identify the shared non-durable subscription 
    # + messageSelector - only messages with properties matching the message selector expression are added to the shared 
    #                     non-durable subscription. A value of null or an empty string indicates that there is no message 
    #                     selector for the shared non-durable subscription. 
    # + return - Returns a jms:MessageConsumer
    remote function createSharedConsumer(Destination topic, string subscriberName,
                                                string messageSelector = "") returns MessageConsumer|error {
         var val = createJmsSharedConsumer(self.jmsSession, topic.getJmsDestination(),
                                           java:fromString(subscriberName), java:fromString(messageSelector));
         if (val is handle) {
             MessageConsumer consumer = new(val);
             return consumer;
         } else {
             return val;
         }
    }

    # Creates a shared durable subscription on the specified topic (if one does not already exist), 
    # specifying a message selector, and creates a consumer on that durable subscription. 
    #
    # + topic - the non-temporary Topic to subscribe to
    # + subscriberName - the name used to identify this subscription
    # + messageSelector - only messages with properties matching the message selector expression are added to the durable subscription. 
    #                     A value of null or an empty string indicates that there is no message selector for the durable subscription. 
    # + return - Returns a jms:MessageConsumer
    remote function createSharedDurableConsumer(Destination topic, string subscriberName,
                                                string messageSelector = "") returns MessageConsumer|error {
         var val = createJmsSharedDurableConsumer(self.jmsSession, topic.getJmsDestination(),
                                                  java:fromString(subscriberName), java:fromString(messageSelector));
         if (val is handle) {
             MessageConsumer consumer = new(val);
             return consumer;
         } else {
             return val;
         }
    }
}

# The Configurations that are related to a JMS session.
#
# + acknowledgementMode - Specifies the session mode that will be used. Valid values are "AUTO_ACKNOWLEDGE",
# "CLIENT_ACKNOWLEDGE", "SESSION_TRANSACTED", and "DUPS_OK_ACKNOWLEDGE".
public type SessionConfiguration record {|
    string acknowledgementMode = "AUTO_ACKNOWLEDGE";
|};

function createJmsMessage(handle session) returns handle|error = @java:Method {
    name: "createMessage",
    'class: "javax.jms.Session"
} external;

function createJmsTextMessage(handle session) returns handle|error = @java:Method {
    name: "createTextMessage",
    'class: "javax.jms.Session"
} external;

isolated function createJmsTextMessageWithText(handle session, handle text) returns handle|error = @java:Method {
    name: "createTextMessage",
    paramTypes: ["java.lang.String"],
    'class: "javax.jms.Session"
} external;

isolated function createJmsMapMessage(handle session) returns handle|error = @java:Method {
    name: "createMapMessage",
    'class: "javax.jms.Session"
} external;

function createJmsStreamMessage(handle session) returns handle|error = @java:Method {
    name: "createStreamMessage",
    'class: "javax.jms.Session"
} external;

isolated function createJmsBytesMessage(handle session) returns handle|error = @java:Method {
    name: "createBytesMessage",
    'class: "javax.jms.Session"
} external;

isolated function createJmsConsumer(handle jmsSession, handle jmsDestination,
        handle selectorString, boolean noLocal) returns handle|error = @java:Method {
    name: "createConsumer",
    paramTypes: ["javax.jms.Destination", "java.lang.String", "boolean"],
    'class: "javax.jms.Session"
} external;

isolated function createJmsSession(handle connection, handle acknowledgmentMode) returns handle|error = @java:Method {
    'class: "io.ballerina.stdlib.java.jms.JmsSessionUtils"
} external;

isolated function unsubscribeJmsSubscription(handle session, handle subscriptionId) returns error? = @java:Method {
    name: "unsubscribe",
    'class: "javax.jms.Session"
} external;

function createJmsProducer(handle session, handle jmsDestination) returns handle|error = @java:Method {
    name: "createProducer",
    'class: "javax.jms.Session"
} external;

function createJmsDurableSubscriber(handle jmsSession, handle subscriberName, handle jmsDestination,
        handle selectorString, boolean noLocal) returns handle|error = @java:Method {
    name: "createDurableSubscriber",
    paramTypes: ["javax.jms.Topic", "java.lang.String", "java.lang.String", "boolean"],
    'class: "javax.jms.Session"
} external;

function createJmsSharedConsumer(handle jmsSession, handle subscriberName, handle jmsDestination,
        handle selectorString) returns handle|error = @java:Method {
    name: "createSharedConsumer",
    paramTypes: ["javax.jms.Topic", "java.lang.String", "java.lang.String"],
    'class: "javax.jms.Session"
} external;

function createJmsSharedDurableConsumer(handle jmsSession, handle subscriberName, handle jmsDestination,
        handle selectorString) returns handle|error = @java:Method {
    name: "createSharedDurableConsumer",
    paramTypes: ["javax.jms.Topic", "java.lang.String", "java.lang.String"],
    'class: "javax.jms.Session"
} external;

isolated function createJmsQueue(handle session, handle queueName) returns handle|error = @java:Method {
    name: "createQueue",
    'class: "javax.jms.Session"
} external;

isolated function createJmsTopic(handle session, handle topicName) returns handle|error = @java:Method {
    name: "createTopic",
    'class: "javax.jms.Session"
} external;

isolated function createTemporaryJmsQueue(handle session) returns handle|error = @java:Method {
    'class: "io.ballerina.stdlib.java.jms.JmsSessionUtils"
} external;

isolated function createTemporaryJmsTopic(handle session) returns handle|error = @java:Method {
    'class: "io.ballerina.stdlib.java.jms.JmsSessionUtils"
} external;
