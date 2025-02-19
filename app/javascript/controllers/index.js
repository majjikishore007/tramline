// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import Flatpickr from "stimulus-flatpickr"
application.register("flatpickr", Flatpickr)

import RevealController from "stimulus-reveal"
application.register("reveal", RevealController)

import Sortable from "stimulus-sortable"
application.register("sortable", Sortable)

import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)

import { Confetti } from "stimulus-confetti"
application.register("confetti", Confetti)

import { Tabs } from "tailwindcss-stimulus-components"
application.register("tabs", Tabs)

import { Popover } from "tailwindcss-stimulus-components"
application.register("popover", Popover)

import TextareaAutogrow from "stimulus-textarea-autogrow"
application.register("textarea-autogrow", TextareaAutogrow)
