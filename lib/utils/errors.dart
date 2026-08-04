enum AppError {errLoadSettings, errSaveSettings, errLoadList, errSaveList, }

sealed class Result<T> {
  const Result();
}  

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure extends Result<void> {
  final AppError error;
  const Failure(this.error);
}

