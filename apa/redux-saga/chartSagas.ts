import { call, put, all } from 'redux-saga/effects'

import { Unpacked } from '@Types'
import { loadChartData } from '@App/api/reports'
import { takeLatestPerKey } from './effects'
import {
  Actions,
  setChartData,
  setAggregateData,
  ChartDataRequestedAction,
  setChartLoading,
  unsetChartLoading,
  setChartErrorMessage,
} from '@Containers/Charts/actions'
import { ERROR_MESSAGE } from '@App/constants/errorMessage'

export function* fetchChartData(action: ChartDataRequestedAction) {
  const {
    metric,
    selectedDate,
    selectedCompareDate,
    selectedFilters,
    selectedTimeZone,
    excludedDimensions,
    granularity,
    compareEnabled,
  } = action.payload

  try {
    yield all([
      put(setChartLoading(metric.value)),
      put(setChartErrorMessage(metric.value, '')),
    ])

    const chartData: Unpacked<ReturnType<typeof loadChartData>> = yield call(
      loadChartData,
      {
        metric,
        selectedDate,
        selectedCompareDate,
        selectedFilters,
        selectedTimeZone,
        excludedDimensions,
        granularity,
        compareEnabled,
      },
    )
    const aggregateData: Unpacked<ReturnType<typeof loadChartData>> = yield call(
      loadChartData,
      {
        metric,
        selectedDate,
        selectedCompareDate,
        selectedFilters,
        selectedTimeZone,
        excludedDimensions,
        compareEnabled,
      },
    )

    yield all([
      put(setChartData(chartData, metric.value)),
      put(setAggregateData(aggregateData, metric.value)),
      put(unsetChartLoading(metric.value)),
    ])
  } catch (error) {
    yield put(setChartErrorMessage(metric.value, ERROR_MESSAGE))
  }
}

export default function* root() {
  yield all([
    takeLatestPerKey(
      Actions.CHART_DATA_REQUESTED,
      fetchChartData,
      ac => ac.payload.metric.value,
    ),
  ])
}
