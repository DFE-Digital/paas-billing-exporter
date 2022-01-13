ORG=dfe
BILLING_URL=https://billing.london.cloud.service.gov.uk
# BILLING_URL=https://new-billing.london.cloud.service.gov.uk
RANGE_START="2022-01-05"
RANGE_STOP="2022-01-08"
ORG_GUID="$(cf org ${ORG} --guid)"

curl -s -G -H "Authorization: $(cf oauth-token)" "${BILLING_URL}/billable_events" \
	--data-urlencode "range_start=${RANGE_START}" \
	--data-urlencode "range_stop=${RANGE_STOP}" \
	--data-urlencode "org_guid=${ORG_GUID}"
