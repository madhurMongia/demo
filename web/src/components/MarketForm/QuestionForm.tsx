import { FormProvider } from "react-hook-form";
import {
  ButtonsWrapper,
  FormStepProps,
  FormWithNextStep,
  FormWithPrevStep,
  MARKET_CATEGORIES,
  QuestionFormValues,
} from ".";
import Input from "../Form/Input";
import Select from "../Form/Select";

export function QuestionForm({
  useFormReturn,
  goToPrevStep,
  goToNextStep,
}: FormStepProps<QuestionFormValues> & FormWithPrevStep & FormWithNextStep) {
  const {
    register,
    formState: { errors, isValid },
    handleSubmit,
  } = useFormReturn;

  return (
    <FormProvider {...useFormReturn}>
      <form onSubmit={handleSubmit(goToNextStep)} className="space-y-[32px]">
        <div>
          <div className="text-[24px] font-semibold mb-[32px]">Question</div>
          <Input
            autoComplete="off"
            {...register("market", {
              required: "This field is required.",
            })}
            className="w-full md:w-2/3"
            errors={errors}
          />
        </div>

        <div>
          <div className="text-[24px] font-semibold mb-[32px]">Category</div>
          <Select
            autoComplete="off"
            {...register("category", {
              required: "This field is required.",
            })}
            options={MARKET_CATEGORIES}
            className="w-full md:w-2/3"
            errors={errors}
          />
        </div>

        <ButtonsWrapper goToPrevStep={goToPrevStep} goToNextStep={goToNextStep} disabled={!isValid} />
      </form>
    </FormProvider>
  );
}
