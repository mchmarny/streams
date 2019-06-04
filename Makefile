
topic:
	gcloud pubsub topics create iotevents

topicless:
	gcloud pubsub topics delete iotevents


catalog:
	gcloud beta data-catalog entries update \
		--lookup-entry='pubsub.topic.cloudylab.iotevents' \
		--schema-from-file=schema.yaml

catalog-check:
	gcloud beta data-catalog entries lookup \
		'pubsub.topic.cloudylab.iotevents'

