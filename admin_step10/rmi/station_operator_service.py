import logging
from models.station_operator import StationOperator

logger = logging.getLogger(__name__)


class StationOperatorRMIService:
    """Remote station-operator authentication service."""

    def __init__(self):
        self.model = StationOperator()
        logger.info("✅ StationOperatorRMIService initialized")

    def authenticate_operator(self, operator_code, password):
        try:
            logger.info("🔐 Station operator login attempt: %s", operator_code)
            return self.model.authenticate(operator_code, password)
        except Exception as exc:
            logger.error("❌ Station operator auth error: %s", exc)
            return {'error': str(exc)}

    def get_operator(self, operator_id):
        try:
            result = self.model.client.table(self.model.table) \
                .select('*') \
                .eq('id', operator_id) \
                .limit(1) \
                .execute()
            return result.data[0] if result.data else None
        except Exception as exc:
            logger.error("❌ Get station operator error: %s", exc)
            return None
