--Start of Global Scope---------------------------------------------------------
print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 2000 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create()

-- Decorations
local textDecoration = View.TextDecoration.create()
textDecoration:setColor(0, 100, 255)
textDecoration:setSize(80)
textDecoration:setPosition(20, 100)

local pointDecoration = View.ShapeDecoration.create()
pointDecoration:setPointSize(10)
pointDecoration:setLineColor(0, 255, 255) -- Blue color scheme for "Teach" mode
pointDecoration:setLineWidth(5)

local foundDecoration = View.ShapeDecoration.create()
foundDecoration:setPointSize(5)
foundDecoration:setLineColor(0, 255, 0) -- Green color scheme for "Found" mode
foundDecoration:setLineWidth(5)

-- Creating a PointMatcher and set parameters
local matcher = Image.Matching.PointMatcher.create()
-- Allow Homography pose transforms as the input images are from different perspectives
matcher:setPoseType('HOMOGRAPHY')
-- The perspective differences and/or area changes are quite small, "LOW" allows for faster matching
matcher:setPoseVariability('LOW')
-- Downsample somewhat for faster matching and to remove some noise details
matcher:setDownsampleFactor(3)

-- Create a fixture to co-transform a polygon with the PointMatcher result
local fixture = Image.Fixture.create()

-- Storing teach pose, required for rectifying images
local teachPose
local rectifyingTransform

-- Storing shape of rectified region
local rectifiedRegionShape

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

--@teach(img:Image)
local function teach(img)
  viewer:clear()
  local imViewId = viewer:addImage(img) -- Present the teach image

  -- Defining teach object position and teach region
  local objectCorners = {
    Point.create(534, 1194),
    Point.create(1215, 1194),
    Point.create(1202, 1799),
    Point.create(586, 1791)
  }
  local teachShape = Shape.createPolyline(objectCorners, true)

  -- Teach the matcher and store the teach pose
  teachPose = matcher:teach(img, teachShape:toPixelRegion(img))

  -- Set reference pose of the fixture object and add the polyline shape
  fixture:setReferencePose(teachPose)
  fixture:appendShape('teachRegion', teachShape)

  -- Get the PointMatcher object model points in the teach image coordinate system for overlay
  local modelPoints = matcher:getModelPoints() -- Model points in model's local coordinate system
  local teachPoints = Point.transform(modelPoints, teachPose)

  -- View teach setup
  viewer:addShape(teachShape, foundDecoration, nil, imViewId)
  viewer:addShape(teachPoints, pointDecoration, nil, imViewId)
  viewer:addText('Teach image - Original', textDecoration, nil, imViewId)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- Rectify the teach image

  -- Defining where the rectified object should end up
  local targetCorners = {
    Point.create(600, 1200),
    Point.create(1200, 1200),
    Point.create(1200, 1800),
    Point.create(600, 1800)
  }
  rectifiedRegionShape = Shape.createPolyline(targetCorners, true)

  -- Generating the rectifying transform, from teach pose to rectified pose
  rectifyingTransform = Transform.createHomography2DFromPoints(objectCorners, targetCorners)

  -- View everything
  viewer:clear()
  local imRect = img:transform(rectifyingTransform)
  imViewId = viewer:addImage(imRect)
  viewer:addShape(rectifiedRegionShape, foundDecoration, nil, imViewId)
  viewer:addText('Teach image - Rectified', textDecoration, nil, imViewId)
  viewer:present()
end

local function match(img, i)
  -- Perform a match operation. The return values are two vectors, one with pose transforms
  -- describing the positions and rotations of the found objects, and one vector with a score between
  -- 0.0 and 1.0 describing the quality of each match. In the current case, we are looking only
  -- for 1 object, so the vectors have length 1.
  local poses,
    scores = matcher:match(img)
  print('Match found with score: ' .. scores[1])

  -- Co-transform the teach shape using the Fixture object to overlay it on the live image
  fixture:transform(poses[1])
  local transformedShape = fixture:getShape('teachRegion')

  -- View the match result
  viewer:clear()
  local imViewId = viewer:addImage(img)
  viewer:addText('Live image ' .. tostring(i) .. ' - Original', textDecoration, nil, imViewId)
  viewer:addShape(transformedShape, foundDecoration, nil, imViewId)
  viewer:present()
  Script.sleep(DELAY) -- For demonstration purpose only

  -- Calculate the rectifying transform and rectify image
  -- Note: The Fixture assists us when we want to transform other objects from the
  -- teach image to the matched image. Here we want to do the opposite,
  -- transforming the matched image to the teach pose and further to the rectified pose.

  -- The final rectifying transform is found by calculating the transform from match pose
  -- to teach pose (match pose transform inverted, composed with the teach pose transform)
  -- and finally composing it with the transform from teach pose to rectified pose.

  -- Alternatively, the corner points of the teach object could be added to a fixture
  -- and then transforming the fixture the usual way to obtain the corner points of a
  -- matched object. These can then be used to estimate a new rectifying transform.
  local rectifyingTrfm = ((poses[1]:invert()):compose(teachPose)):compose(rectifyingTransform)
  local imRectified = img:transform(rectifyingTrfm)

  -- View rectified image
  viewer:clear()
  imViewId = viewer:addImage(imRectified)
  viewer:addShape(rectifiedRegionShape, foundDecoration, nil, imViewId)
  viewer:addText('Live image ' .. tostring(i) .. ' - Rectified', textDecoration, nil, imViewId)
  viewer:present()
end

local function main()
  -- Loading Teach image from resources and calling teach() function
  local teachImage = Image.load('resources/teach.bmp')
  teach(teachImage)
  Script.sleep(DELAY) -- for demonstration purpose only

  -- Loading images from resource folder and calling match() function
  for i = 1, 3 do
    local liveImage = Image.load('resources/' .. i .. '.bmp')
    match(liveImage, i)
    Script.sleep(DELAY) -- for demonstration purpose only
  end

  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
