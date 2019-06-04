# streams

IoT stream processing using GCP IoT Core, PubSub, BigQuery, Dataflow

BigQuery has recently added support for SQL queries over PubSub topic payload (Cloud Dataflow SQL, alpha). As a result it is now much easier to build stream analytics systems. To illustrate this, I will demo the use of tumble windowing function in BigQuery over a mocked IoT data stream enabled by Google's IoT Core platform.

> You can learn more about windowing functions and streaming pipelines [here](https://cloud.google.com/dataflow/docs/guides/sql/streaming-pipeline-basics)

# Data Source

To demo the BigQuery SQL capability over streamed data we will need some.... data. To do this, we will use my [iot-event-maker](https://github.com/mchmarny/iot-event-maker) which will:

* Configure IoT Core (create a registry and configure device)
* Configure Cloud PubSub topic to queue the data sent to the IoT Core device
* Generate mocked measurement data (CPU, RAM, LOAD etc.) and send it to the IoT Core device

To set this all app, follow the instruction outlined [here](https://github.com/mchmarny/iot-event-maker). When defining PubSun topic call it `iotevents` and for metric name use `utilization` (`--metric` flag). Also, if you start multiple instances of [iot-event-maker](https://github.com/mchmarny/iot-event-maker) make sure to change the `--device` flag (i.e. `client-1`, `client-2`, `client-3` etc).

# Data Stream

Assuming you set up [iot-event-maker](https://github.com/mchmarny/iot-event-maker) correctly, you should now have a Cloud PubSub topic called `iotevents` queueing your mocked events. Each one of these events holds JSON payload similar to this:

```json
{
    "source_id":"client-1",
    "event_id":"eid-20f9b215-4920-439d-9577-561fe776af4d",
    "event_ts":"2019-06-03T17:22:38.351698Z",
    "label":"utilization",
    "mem_used":5.4931640625,
    "cpu_used":10.526315789473683,
    "load_1":1.4,
    "load_5":1.62,
    "load_15":1.68,
    "random_metric":4.988959069746996
}
```

What we are going to do now is create stream processing pipeline that will process the streamed data in 15 sec windows.

# Data Processing

The full walk-through is [here](https://cloud.google.com/dataflow/docs/guides/sql/dataflow-sql-ui-walkthrough). Follow these instructions to enable the API and create the necessary service account.


## Register Schema

First, lets add the

```shell
gcloud beta data-catalog entries update \
    --lookup-entry='pubsub.topic.`project_ID`.iotevents' \
    --schema-from-file=schema.yaml
```

### Create Job

 And using [Tumbling windows function](https://cloud.google.com/dataflow/docs/guides/sql/streaming-pipeline-basics#tumbling-windows) to display the streamed data in non overlapping time interval.

```sql
SELECT
    c.label as metric,
    TUMBLE_START("INTERVAL 10 SECOND") AS period_start,
    MIN(c.load_1) as load_min,
    MAX(c.load_1) as load_max,
    AVG(c.load_1) as load_avg
FROM pubsub.topic.`project_ID`.iotevents as c
GROUP BY
    c.label,
    TUMBLE(c.event_ts, "INTERVAL 10 SECOND")
```

### Select Events

```sql
SELECT *
FROM buttons.iotevents_10s c
ORDER BY c.period_start DESC
```

Should return

```shell
| Row | button_color | period_start            | click_sum |
| --- | ------------ | ----------------------- | --------- |
| 1   | white        | 2019-05-31 23:16:25 UTC | 14        |
| 2   | white        | 2019-05-31 23:13:20 UTC | 1         |
| 3   | green        | 2019-05-31 23:13:20 UTC | 1         |
| 4   | black        | 2019-05-31 23:13:15 UTC | 4         |
```

