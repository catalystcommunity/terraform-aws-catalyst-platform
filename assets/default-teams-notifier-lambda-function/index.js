const https = require("https");
const url = require("url");

const postTeamsMessage = function (webhookUrl, message, callback) {
  let options = url.parse(webhookUrl);
  let payload = JSON.stringify(message);
  options.method = "POST";
  options.headers = {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(payload),
  };

  let postReq = https.request(options, function (res) {
    res.on("error", (e) => {
      callback(Error(e));
    });
    res.on("end", (res) => {
      callback(null, res.statusCode);
    });
    return res;
  });

  postReq.write(payload);
  postReq.end();
};

const parseCloudwatchAlarm = function (event) {
  let message = JSON.parse(event.Records[0].Sns.Message);
  let color = "FFCC00";

  if (message.NewStateValue === "ALARM") {
    color = "CC3300";
  } else if (message.NewStateValue === "OK") {
    color = "339900";
  }

  return {
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    themeColor: color,
    summary: "CloudWatch Alarm",
    sections: [
      {
        activityTitle: message.AlarmName,
        activitySubtitle: message.AlarmDescription,
        facts: [
          {
            name: "Trigger",
            value:
              `${message.Trigger.Statistic} ${message.Trigger.MetricName} ` +
              `${message.Trigger.ComparisonOperator} ${message.Trigger.Threshold} ` +
              `for ${message.Trigger.EvaluationPeriods} period(s) of ` +
              `${message.Trigger.Period} seconds."`,
          },
          {
            name: "Old State",
            value: message.OldStateValue,
          },
          {
            name: "Current State",
            value: message.NewStateValue,
          },
        ],
        markdown: true,
      },
    ],
  };
};

exports.handler = function (event, context, callback) {
  // check if the URL environment variable is set
  if (!("WEBHOOK_URL" in process.env)) {
    throw new Error("Missing WEBHOOK_URL environment variable!");
  }

  let url = process.env.WEBHOOK_URL;
  let message = parseCloudwatchAlarm(event);

  postTeamsMessage(url, message, callback);
};
