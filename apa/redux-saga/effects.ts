import { call, takeEvery, join, cancel, fork } from 'redux-saga/effects'

export const takeLatestPerKey = (patternOrChannel, worker, keySelector, ...args) => {
  return fork(function* () {
    const tasks = {}

    yield takeEvery(patternOrChannel, function* (action) {
      const key = yield call(keySelector, action)

      if (tasks[key]) {
        yield cancel(tasks[key])
      }

      tasks[key] = yield fork(worker, ...args, action)

      yield join(tasks[key])

      if (tasks[key] && !tasks[key].isRunning()) {
        delete tasks[key]
      }
    })
  })
}
