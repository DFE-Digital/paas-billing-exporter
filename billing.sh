ORG=dfe
BILLING_URL=https://billing.london.cloud.service.gov.uk
RANGE_START="2021-07-01"
RANGE_STOP="2021-07-22"
ORG_GUID="$(cf org ${ORG} --guid)"

curl -s -G -H "Authorization: $(cf oauth-token)" "${BILLING_URL}/billable_events" \
	--data-urlencode "range_start=${RANGE_START}" \
	--data-urlencode "range_stop=${RANGE_STOP}" \
	--data-urlencode "org_guid=${ORG_GUID}"
