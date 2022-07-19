const https = require("https");
const url = require("url");

const postSlackMessage = function (webhookUrl, message, callback) {
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
    text: "*CloudWatch Alarm*",
    attachments: [
      {
        color: color,
        fields: [
          {
            title: "Alarm Name",
            value: message.AlarmName,
            short: true,
          },
          {
            title: "Alarm Description",
            value: message.AlarmDescription,
            short: false,
          },
          {
            title: "Trigger",
            value:
              `${message.Trigger.Statistic} ${message.Trigger.MetricName} ` +
              `${message.Trigger.ComparisonOperator} ${message.Trigger.Threshold} ` +
              `for ${message.Trigger.EvaluationPeriods} period(s) of ` +
              `${message.Trigger.Period} seconds."`,
            short: false,
          },
          {
            title: "Old State",
            value: message.OldStateValue,
            short: true,
          },
          {
            title: "Current State",
            value: message.NewStateValue,
            short: true,
          },
        ],
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

  postSlackMessage(url, message, callback);
};
